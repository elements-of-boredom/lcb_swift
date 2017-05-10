//
//  Bucket.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/21/17.
//
//

import Foundation
import libcouchbase

public class Bucket {
    internal var instance : lcb_t?
    private let name:String
    private let userName:String
    private let password:String?
    
    /// Default Bucket initializer
    ///
    /// - Parameters:
    ///   - name: bucket name
    ///   - connection: URL in the format of couchbase://ip1,dns2,ip3/bucketname?options=values
    ///   - password: if provided will attempt SAML auth using password
    /// - Throws: CouchbaseError.FailedInit if connection fails
    init(bucketName name:String, connection: URL, password:String?) throws {
        self.name = name
        self.password = password
        self.userName = name
        
        var cropts:lcb_create_st = lcb_create_st()
        cropts.version = 3;
        cropts.v.v3.connstr = connection.absoluteString.utf8String
        
        
        //TODO: http://docs.couchbase.com/sdk-api/couchbase-c-client-2.4.0-beta/group___l_c_b___e_r_r_o_r_s.html
        //Actuall do something w/ the error maybe?
        var err:lcb_error_t
        err = lcb_create( &self.instance, &cropts )
        if ( err != LCB_SUCCESS ) {
            throw CouchbaseError.FailedInit(("Couldn't create instance"))
        }
        
        // connecting
        lcb_connect(instance)
        lcb_wait(instance)
        err = lcb_get_bootstrap_status(instance)
        if ( err != LCB_SUCCESS ) {
            throw CouchbaseError.FailedConnect("Couldn't connect to the instance")
        }
        
        //register callback
        lcb_set_get_callback(self.instance, BucketCallbacks.get_callback)
        //lcb_install_callback3(self.instance, Int32(LCB_CALLBACK_GET.rawValue), get_callback);
        lcb_install_callback3(self.instance, Int32(LCB_CALLBACK_STORE.rawValue), BucketCallbacks.set_callback);
        lcb_install_callback3(self.instance, Int32(LCB_CALLBACK_ENDURE.rawValue), BucketCallbacks.set_callback);
        lcb_install_callback3(self.instance, Int32(LCB_CALLBACK_REMOVE.rawValue), BucketCallbacks.remove_callback)
    }
}

// - MARK: Key based functions
extension Bucket {
    
    /// Rather than setting the contents of the entire document, take the value specified and append it to the existing
    /// document value.
    ///
    /// - Parameters:
    ///   - key: Document Key
    ///   - value: String value to append
    ///   - options: options for the insert operation
    ///   - completion: Callback that will be called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func append(key:String, value:String, options:StoreOptions = StoreOptions(), completion: @escaping OpCallback ) throws {
        
        var cmdOptions = CmdOptions()
        cmdOptions.dataTypeFlags = .Reserved
        cmdOptions.operation = .Append
        cmdOptions.expiry = options.expiry
        cmdOptions.persistTo = options.persistTo
        cmdOptions.replicateTo = options.persistTo
        
        var cmd  = createStoreCMD(cmdOptions, key: key)
        LCB_CMD_SET_VALUE(&cmd, value, value.utf8.count)
        
        try self.invokeStore(cmd: &cmd, options: cmdOptions, callback: completion)
    }

    
    /// Increments or decrements a key's numeric value
    ///
    /// - Parameters:
    ///   - key: Document Key
    ///   - delta: The amount to add or subtract from the counter value.
    ///   - options: options for the counter operation
    ///   - initial: Sets the initial value for the document if it does not exist. Not specifying a value will cause the operation
    ///     to fail if the document does not exist.
    ///   - completion: callback which is called when the operation completes.
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func counter(key:String, delta:Int64, initial:Int64? = nil, options:StoreOptions = StoreOptions(), completion: @escaping OpCallback) throws {
        var ccmd = lcb_CMDCOUNTER()
        ccmd.key.type = LCB_KV_COPY
        ccmd.key.contig.bytes = key.rawUTF8String
        ccmd.key.contig.nbytes = key.utf8.count

        ccmd.exptime = lcb_U32(options.expiry)
        ccmd.delta = delta
        if let initial = initial {
            ccmd.initial = lcb_U64(initial)
            ccmd.create = 1
        }
        
        let delegate = CallbackDelegate(isDelete: false, persistTo: options.persistTo, replicateTo: options.replicateTo)
        delegate.callback = completion
        let retainedCookie = Unmanaged.passRetained(delegate)
        
        let err = lcb_counter3(instance, retainedCookie.toOpaque(), &ccmd)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            let message = lcb_errortext(instance, err)
            throw CouchbaseError.FailedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        lcb_wait(instance); // get_callback is invoked here
    }
    
    
    /// Destroys and releases all allocated resources owned by the bucket.
    /// Making any further calls after disconnecting will most likely cause application crashes
    /// Any pending operation's callbacks will not be invoked.
    public func disconnect() {
        lcb_destroy(self.instance)
    }
    
    
    /// Retreives a document by key.
    ///
    /// - Parameters:
    ///   - key: Document key
    ///   - completion: Callback which is called on operation completion.
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func get(key:String, completion: @escaping OpCallback) throws {
        var getCMD = createGetCMD(GetOptions(),key:key)
        try invokeGet(cmd: &getCMD, callback: completion)
    }
    
    
    /// Locks the document on the server and retreives it. While locked, any attempts to 
    /// modify the document without providing the current CAS will fail until the lock
    /// is released by calling `unlock`, or by performing a storage operation (`upsert`,`replace`,`append`)
    /// while providing the current CAS. Attempting to lock a locked document will fail.
    ///
    /// - Parameters:
    ///   - key: Document key
    ///   - lockTime: The duration of time the lock should be held for. This value is capped at 30 seconds
    ///   - completion: Callback which is called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func getAndLock(key:String, lockTime:UInt32 = 15, completion: @escaping OpCallback) throws {
        let options = GetOptions(expiry: min(lockTime,UInt32(30)), lock: true, cas: 0, cmdflags: 0)
        var getCMD = createGetCMD(options,key:key)
        try invokeGet(cmd: &getCMD, callback:completion)

    }
    
    
    /// Gets a document and updates its expiry at the same time
    ///
    /// - Parameters:
    ///   - key: Document key
    ///   - expiry: This is either an absolute Unix time stamp or a relative offset from now, in seconds.
    ///      If the value of this number is greater than the value of thirty days in seconds, then it is a Unix timestamp.
    ///   - completion: Callback which is called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func getAndTouch(key:String, expiry:UInt32, completion: @escaping OpCallback) throws {
        let options = GetOptions(expiry: expiry, lock: false, cas: 0, cmdflags: 0)
        var getCMD = createGetCMD(options,key:key)
        try invokeGet(cmd: &getCMD, callback: completion)
    }
    
    
    /// Retreives a list of documents returned as a dictionary of key:OpCallback, and an error count
    ///
    /// - Parameters:
    ///   - keys: Array of Document keys
    ///   - completion: Callback which receives a `MultiCallbackResult`
    public func getMulti(keys:[String], completion:@escaping MultiCallback) {
        let dgroup = DispatchGroup()
        var output = [String: OperationResult]()
        for key in keys {
            dgroup.enter()
            var getCMD = self.createGetCMD(GetOptions(),key:key)
            do {
                try self.invokeGet(cmd: &getCMD) { result in
                    output[key] = result
                    dgroup.leave()
                }
            } catch {
                dgroup.leave()
                output[key] = OperationResult.Error("Couldn't schedule operation! \(error)")
            }
        }

        dgroup.notify(queue: DispatchQueue.main) {
            //call completion
            let errcount = output.filter{key,value in
                if case (.Error(_)) = value{
                    return true
                }else{
                    return false
                }
            }.count
            completion(.Success(UInt(errcount), output))
        }
    }
    
    
    /// Gets a document from a replica server in the cluster
    ///
    /// - Parameters:
    ///   - key: Document key
    ///   - index: the index for which replica you want to receive the value from.
    ///     when left undefined, it uses the value from the first server in the list
    ///   - completion: Callback which is called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func getReplica(key:String, index:Int32?, completion: @escaping OpCallback) throws {
        var getRCMD = lcb_CMDGETREPLICA()
        
        if let index = index {
            getRCMD.strategy = LCB_REPLICA_SELECT
            getRCMD.index = index
        }else{
            getRCMD.strategy = LCB_REPLICA_FIRST
        }
        
        let delegate = CallbackDelegate()
        delegate.callback = completion
        let retainedCookie = Unmanaged.passRetained(delegate)

        let err = lcb_rget3(instance, retainedCookie.toOpaque(), &getRCMD)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            let message = lcb_errortext(instance, err)
            throw CouchbaseError.FailedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        lcb_wait(instance); // get_callback is invoked here
        
    }
    
    
    /// Inserts a document with the provided key. Will fail if the document already exists
    ///
    /// - Parameters:
    ///   - key: Document key
    ///   - value: Document contents
    ///   - options: options for the insert operation
    ///   - completion: Callback which is called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func insert(key:String, value:Any, options:StoreOptions = StoreOptions(), completion: @escaping OpCallback ) throws {
        
        guard let jsonString = try Bucket.encodeValue(value: value) else {
            throw CouchbaseError.FailedSerialization("value provided is not in a proper format to be serialized")
        }
        var cmdOptions = CmdOptions()
        cmdOptions.dataTypeFlags = .Json
        cmdOptions.operation = .Insert
        cmdOptions.expiry = options.expiry
        cmdOptions.persistTo = options.persistTo
        cmdOptions.replicateTo = options.replicateTo
        
        var cmd  = createStoreCMD(cmdOptions, key: key)
        LCB_CMD_SET_VALUE(&cmd, jsonString, jsonString.utf8.count)
        
        try self.invokeStore(cmd: &cmd, options:cmdOptions, callback:completion)
    }
    
    
    /// Prepend a string to an existing document.
    ///
    /// - Parameters:
    ///   - key: Documetn Key
    ///   - value: string to prepend
    ///   - options: options for prepend operation
    ///   - completion: Callback which is called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func prepend(key:String, value:String, options:StoreOptions = StoreOptions(), completion: @escaping OpCallback ) throws {
        
        var cmdOptions = CmdOptions()
        cmdOptions.dataTypeFlags = .Reserved
        cmdOptions.operation = .Prepend
        cmdOptions.expiry = options.expiry
        cmdOptions.persistTo = options.persistTo
        cmdOptions.replicateTo = options.persistTo
        
        var cmd  = createStoreCMD(cmdOptions, key: key)
        LCB_CMD_SET_VALUE(&cmd, value, value.utf8.count)
        
        try self.invokeStore(cmd: &cmd, options: cmdOptions, callback: completion)
    }
    
    
    /// Deletes a document from the server
    ///
    /// - Parameters:
    ///   - key: Document Key
    ///   - options: options for the remove operation
    ///   - completion: Callback which is called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func remove(key:String, options:StoreOptions = StoreOptions(), completion: @escaping OpCallback) throws {
        var rCMD = lcb_CMDREMOVE()
        rCMD.key.type = LCB_KV_COPY
        rCMD.key.contig.bytes = key.rawUTF8String
        rCMD.key.contig.nbytes = key.utf8.count
        rCMD.cas = options.cas
        
        let delegate = CallbackDelegate(isDelete: true, persistTo: options.persistTo, replicateTo: options.replicateTo)
        delegate.callback = completion
        let retainedCookie = Unmanaged.passRetained(delegate)
        
        let err = lcb_remove3(instance, retainedCookie.toOpaque(), &rCMD)
        
        if (err != LCB_SUCCESS) {
            let message = lcb_errortext(instance, err)
            throw CouchbaseError.FailedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        lcb_wait(instance); // get_callback is invoked here
    }
    
    
    /// Stores a document to the bucket. Will not succeed if the document key does not already exist.
    ///
    /// - Parameters:
    ///   - key: Document key
    ///   - value: Document contents
    ///   - options: options for a replace operation
    ///   - completion: Callback that will be called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule, FailedSerialization
    public func replace(key:String, value:Any, options:StoreOptions = StoreOptions(), completion: @escaping OpCallback ) throws {

        guard let jsonString = try Bucket.encodeValue(value: value) else {
            throw CouchbaseError.FailedSerialization("value provided is not in a proper format to be serialized")
        }
        var cmdOptions = CmdOptions()
        cmdOptions.dataTypeFlags = .Json
        cmdOptions.operation = .Upsert
        cmdOptions.expiry = options.expiry
        cmdOptions.persistTo = options.persistTo
        cmdOptions.replicateTo = options.replicateTo
        
        var cmd  = createStoreCMD(cmdOptions, key: key)
        LCB_CMD_SET_VALUE(&cmd, jsonString, jsonString.utf8.count)
        
        try self.invokeStore(cmd: &cmd, options: cmdOptions, callback: completion)
    }
    
    
    /// Updates the document's expiration time
    ///
    /// - Parameters:
    ///   - key: Document Key
    ///   - expiry: This is either an absolute Unix time stamp or a relative offset from now, in seconds. 
    ///     If the value of this number is greater than the value of thirty days in seconds, then it is a Unix timestamp.
    ///   - completion: Callback that is called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func touch(key:String, expiry:UInt32, completion: @escaping OpCallback) throws {
        var cmd = lcb_CMDTOUCH()
        cmd.exptime = expiry
        
        let delegate = CallbackDelegate()
        delegate.callback = completion
        let retainedCookie = Unmanaged.passRetained(delegate)
        
        let err = lcb_touch3(instance, retainedCookie.toOpaque(), &cmd)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            let message = lcb_errortext(instance, err)
            throw CouchbaseError.FailedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        lcb_wait(instance); // set_callback is invoked here
    }
    
    
    /// Unlocks a previously locked document
    ///
    /// - Parameters:
    ///   - key: Document Key
    ///   - cas: CAS value of the document being unlocked
    ///   - completion: Callback that will be called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func unlock(key:String, cas:UInt64, completion: @escaping OpCallback ) throws {

        var cmd  = lcb_CMDUNLOCK()
        cmd.cas = cas
        LCB_CMD_SET_KEY(&cmd, key,key.utf8.count)
        
        let delegate = CallbackDelegate()
        delegate.callback = completion
        let retainedCookie = Unmanaged.passRetained(delegate)
        
        let err = lcb_unlock3(instance, retainedCookie.toOpaque(), &cmd)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            let message = lcb_errortext(instance, err)
            throw CouchbaseError.FailedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        lcb_wait(instance); // set_callback is invoked here
    }
    
    
    /// Stores a document to the bucket. It will be created if it does not exist and updated if it already exists
    ///
    /// - Parameters:
    ///   - key: Document Key
    ///   - value: Document value
    ///   - options: options for the Upsert operation
    ///   - completion: Callback that will be called on completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func upsert(key:String, value:Any, options:StoreOptions = StoreOptions(), completion: @escaping OpCallback ) throws {

        guard let jsonString = try Bucket.encodeValue(value: value) else {
            throw CouchbaseError.FailedSerialization("value provided is not in a proper format to be serialized")
        }
        var cmdOptions = CmdOptions()
        cmdOptions.dataTypeFlags = .Json
        cmdOptions.operation = .Upsert
        cmdOptions.expiry = options.expiry
        cmdOptions.persistTo = options.persistTo
        cmdOptions.replicateTo = options.replicateTo
        
        var cmd  = createStoreCMD(cmdOptions, key: key)
        LCB_CMD_SET_VALUE(&cmd, jsonString, jsonString.utf8.count)
        
        try self.invokeStore(cmd: &cmd, options: cmdOptions, callback: completion)
    }
}

// - MARK: SubDocument API
extension Bucket {

    public func lookupIn(key:String, specs:String) {
        
    }
    
    public func mutateIn(key:String, specs:String) {
        
    }
    
    // - MARK: MapReduce/Views
    
    public func query(design:String, view:String, isDevelopment:Bool) {
        
    }
    
}

// - MARK: Private helpers
extension Bucket {
    /// Helper which consolidates lcbCMDGET initialization
    ///
    /// - Parameters:
    ///   - options: Options used for initialization
    ///   - key: Document Key
    /// - Returns: libcouchbase command object used for retrieving a single object
    fileprivate func createGetCMD(_ options:GetOptions, key:String) -> lcb_CMDGET {
        var getCMD = lcb_CMDGET()
        getCMD.cmdflags = lcb_U32(options.cmdflags)
        if options.lock {
            getCMD.lock = 1
            getCMD.exptime = lcb_U32(options.expiry)
        }
        getCMD.cas = options.cas
        LCB_CMD_SET_KEY(&getCMD, key, key.utf8.count)
        
        return getCMD
    }
    
    
    
    /// Helper which conslidates lcb_CMDSTORE initialization
    ///
    /// - Parameters:
    ///   - options: options used for initialization
    ///   - key: Document key
    /// - Returns: libcouchbase command object used for storing a document
    fileprivate func createStoreCMD(_ options:CmdOptions, key:String) -> lcb_CMDSTORE {
        var storeCMD = lcb_CMDSTORE()
        storeCMD.cas = options.cas
        storeCMD.cmdflags = options.cmdflags
        storeCMD.operation = options.operation.toLcbType()
        storeCMD.flags = options.dataTypeFlags.rawValue
        
        LCB_CMD_SET_KEY(&storeCMD, key, key.utf8.count)
        return storeCMD
    }

    
    /// Helper that creates the callback delegate and calls lcb_get3
    ///
    /// - Parameters:
    ///   - cmd: the get command to queue
    ///   - callback: user supplied callback method to call on completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    fileprivate func invokeGet(cmd: inout lcb_CMDGET, callback:@escaping OpCallback) throws {
        let delegate = CallbackDelegate()
        delegate.callback = callback
        
        let retainedCookie = Unmanaged.passRetained(delegate)
        
        let err = lcb_get3(instance, retainedCookie.toOpaque(), &cmd)
        
        if (err != LCB_SUCCESS) {
            let message = lcb_errortext(instance, err)
            throw CouchbaseError.FailedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        lcb_wait(instance); // get_callback is invoked here
    }
    
    
    /// Helper that creates the callback delegate and calls lcb_store3
    ///
    /// - Parameters:
    ///   - cmd: the storage command to queue
    ///   - options: command options, including durability constraints
    ///   - callback: user supplied callback method to call on completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    fileprivate func invokeStore(cmd: inout lcb_CMDSTORE, options: CmdOptions, callback: @escaping OpCallback) throws {
        let delegate = CallbackDelegate(persistTo: options.persistTo, replicateTo: options.replicateTo)
        delegate.callback = callback
        
        let retainedCookie = Unmanaged.passRetained(delegate)
        
        let err = lcb_store3(instance, retainedCookie.toOpaque(), &cmd)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            let message = lcb_errortext(instance, err)
            throw CouchbaseError.FailedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        lcb_wait(instance); // set_callback is invoked here

    }
    
    
    /// When requested, creates a durability scheduled operation which calls the delegate on completion
    ///
    /// - Parameters:
    ///   - instance: instance of libcouchbase on which to schedule the operation
    ///   - response: libcouchbase response which is the result of the operation we want to ensure durability on
    ///   - delegate: user supplied callback to call on completion
    internal static func endure(instance:lcb_t, response:lcb_RESPBASE, delegate : CallbackDelegate) {
        
        //This shouldn't happen as it is checked before calling endure
        //but just to safeguard, if we don't have a user completion
        //then there is literally nothing left to do.
        guard let callback = delegate.callback else {
            return
        }
        
        var durCMD = lcb_CMDENDURE()
        durCMD.key.type = LCB_KV_COPY
        durCMD.key.contig.bytes = response.key
        durCMD.key.contig.nbytes = response.nkey
        durCMD.cas = response.cas

        var dur_opts = lcb_durability_opts_t()
        dur_opts.v.v0.persist_to = lcb_U16(delegate.persistTo)
        dur_opts.v.v0.replicate_to = lcb_U16(delegate.replicateTo)
        dur_opts.v.v0.check_delete = delegate.isDelete ? 1 : 0
        
        //we cant simply pass err like we do elsewhere because ctxnew expects a memory pointer to where to write the error
        let err = UnsafeMutablePointer<lcb_error_t>.allocate(capacity: 1)
        let multiCMDCtx = lcb_endure3_ctxnew(instance, &dur_opts, err)
        if err.pointee != LCB_SUCCESS {
            let message = lcb_errortext(instance, err.pointee)
            callback(OperationResult.Error("Couldn't schedule durability operation! \(message)"))
        }
        
        //While we need to make sure the context exists, we cannot use cmd as an argument because
        //it would require we do `var cmd = multiCMDCtx?.pointee` which makes it a mutable copy.
        //This then causes bad access errors inside the C api, because we've copied portions of the 
        //MultiCmdCtx in memory. Using `let` creates effectively a "pointer" to
        //the actual item in memory so we can use it when calling the api, but not as an argument.
        //All ForcedUnwraps are therefore gauranteed because we first checked here.
        if let cmd = multiCMDCtx?.pointee {
            //Deal with the fact that lcb_CMDENDURE is built using complex macro's in C, and therefore
            //there is no real relationship between lcb_CMDENDURE and lcb_CMDBASE
            withUnsafePointer(to: &durCMD) {
                $0.withMemoryRebound(to: lcb_CMDBASE.self, capacity: 1) { cmdbase in
                    let errCmd = cmd.addcmd(&multiCMDCtx!.pointee, cmdbase)
                    if errCmd != LCB_SUCCESS {
                        cmd.fail(&multiCMDCtx!.pointee)
                        let message = lcb_errortext(instance, errCmd)
                        callback(OperationResult.Error("Couldn't schedule durability operation! \(message)"))
                    }
                }
            }
            
            let delegate = CallbackDelegate()
            delegate.callback = callback
            
            let retainedCookie = Unmanaged.passRetained(delegate)
            
            let err = cmd.done(&multiCMDCtx!.pointee,retainedCookie.toOpaque())
            if err != LCB_SUCCESS {
                let message = lcb_errortext(instance, err)
                callback(OperationResult.Error("Unable to schedule durability operation! \(message)"))
            }
            
        } else {
            callback(OperationResult.Error("Couldn't schedule durability operation, missing MultiCommand Context!"))
        }
    }
    
    internal static func encodeValue(value:Any) throws -> String? {
        if JSONSerialization.isValidJSONObject(value) {
            return String(data: try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted), encoding:.utf8)
        }
        throw CouchbaseError.FailedSerialization("Value provided is not in a format that can be json serialized")
        
    }
    
    
    /// decodes a JSON string into a json object (Any)-> [String:Any]
    /// this convenience call is here so that we can wrap all the work in an autoreleasepool because
    /// both String.data(using:), AND .jsonObject leak memory at a questionable rate.
    ///
    /// - Parameter value: json string to decode
    /// - Returns: Returns a Foundation object from given JSON data.
    /// - Throws: exceptions
    internal static func decodeValue(value:String) throws -> Any {
        return try autoreleasepool {
            if let value = value.data(using: .utf8) {
                return try JSONSerialization.jsonObject(with: value, options: [])
            }
            throw LCBSwiftError.NotImplemented("Placeholder")
        }
    }
}
