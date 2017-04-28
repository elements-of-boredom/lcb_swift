//
//  Bucket.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/21/17.
//
//

import Foundation
import libcouchbase

public typealias OpCallback = (OperationResult)->()
public typealias MultiCallback = (MultiCallbackResult)->()


public class Bucket {
    private var instance : lcb_t?
    private let name:String
    private let userName:String
    private let password:String?
    
    private static var callbacks = [String:OpCallback]()
    private static var multiCallbacks = [String:MultiCallback]()
    
    // - MARK: Members
    public let clientVersion : String = "0.1"
    
    /// The amount of time (in microseconds) that the Bucket will wait before
    /// forcing a configuration refresh. If no refresh occurs before this period
    /// while a configuration is marked invalid, an update will be triggered.
    public var configThrottle : Int32 {
        get {
            var value :Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_CONFDELAY_THRESH,&value)
            return value
        }
        set (newValue) {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_CONFDELAY_THRESH,pointer.toOpaque())
        }
    }
    
    
    /// Initial bootstrapping timeout.
    /// This is how long the client will wait to obtain the initial configuration
    public var connectionTimeout : Int32 {
        get {
            var value :Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_CONFIGURATION_TIMEOUT,&value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_CONFIGURATION_TIMEOUT,pointer.toOpaque())
        }
    }
    
    
    /// Polling grace interval for lcb_durability_poll()
    /// This is the time the client will wait between repeated probes to a given server
    public var durabilityInterval : Int32 {
        get {
            var value :Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_DURABILITY_INTERVAL,&value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_DURABILITY_INTERVAL,pointer.toOpaque())
        }
    }
    
    
    /// Default timeout for how long the client will spend sending repeated probes to a 
    /// given key's vBucket masters and replica's before they are deemed not to have 
    /// satisfied durability requirements.
    public var durabilityTimeout : Int32 {
        get {
            var value :Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_DURABILITY_TIMEOUT,&value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_DURABILITY_TIMEOUT,pointer.toOpaque())
        }
    }
    
    
    /// Returns the libcouchbase version as a string.
    public var lcbVersion : String {
        get {
            //calls to utf8String cant really fail, we could get bad data though
            return String(utf8String:lcb_get_version(nil))!
        }
    }
    
    
    /// The management timeout is the time the bucket will wait for a response
    /// from the server for a management request. (Non-view Http Requests)
    public var managementTimeout : Int32 {
        get {
            var value :Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_HTTP_TIMEOUT,&value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_HTTP_TIMEOUT,pointer.toOpaque())
        }
    }
    
    
    /// N1QL Timeout is the time that a Bucket will wait for a response from the server
    /// for a n1ql request.
    public var n1qlTimeout : Int32 {
        get {
            var value :Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_N1QL_TIMEOUT,&value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_N1QL_TIMEOUT,pointer.toOpaque())
        }
    }
    
    
    /// Per node configuration timeout.
    /// The per-node configuration timeout sets the amount of time to wait for each node within the bootstrap/configuration process.
    /// This interval is a subset of the `connectionTimeout` option mentioned above and is intended to ensure that the bootstrap process
    /// does not wait too long for a given node. Nodes that are physically offline may never respond and it may take a long time until
    /// they are detected as being offline
    public var nodeConnectionTimeout : Int32 {
        get {
            var value :Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_CONFIG_NODE_TIMEOUT,&value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_CONFIG_NODE_TIMEOUT,pointer.toOpaque())
        }
    }
    
    
    /// The operation timeout.
    /// The operation timeout is the maximum amount of time the SDK will wait for an operation to receive
    /// a response before invoking its callback with a failed status.
    /// Operations can timeout if the server is taking to long to respond, or an updated cluster config
    /// has not been received within the `configThrottle` time window.
    public var operationTimeout : Int32 {
        get {
            var value :Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_OP_TIMEOUT,&value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_OP_TIMEOUT,pointer.toOpaque())
        }
    }

    
    /// The view timeout.
    /// The view timeout is the maximum amount of time the SDK will wait for HTTP requests of the `view` type
    public var viewTimeout : Int32 {
        get {
            var value :Int32 = 0
            lcb_cntl(instance, LCB_CNTL_GET, LCB_CNTL_OP_TIMEOUT,&value)
            return value
        }
        set {
            let pointer = Unmanaged<AnyObject>.passUnretained(newValue as AnyObject)
            lcb_cntl(instance, LCB_CNTL_SET, LCB_CNTL_OP_TIMEOUT,pointer.toOpaque())
        }
    }

    // - MARK: Callbacks
    private let get_callback:lcb_get_callback = {
        (instance, cookie, err, resp) -> Void in
        
        //Early out if we have no completion callback
        guard let callback = cookie,
            let uuid = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? String,
            let completion = Bucket.callbacks[uuid] else{
            return
        }
        
        //Clean up our callback.
        Bucket.callbacks.removeValue(forKey: uuid)
        
        if err != LCB_SUCCESS {
            completion(OperationResult.Error(Bucket.lcb_errortext(instance,err)))
            return
        }
        
        guard let response = resp?.pointee.v.v0 else{
            completion(OperationResult.Error("Success with No response found"))
            return
        }
        
        let bytes = Data(bytes:response.bytes, count:response.nbytes)
        let value = String(data: bytes , encoding: String.Encoding.utf8)!
        do {
            var json = try JSONSerialization.jsonObject(with: bytes, options: [])
            completion(OperationResult.Success(value: json, cas: response.cas))
        } catch {
            completion(OperationResult.Error("Serialization error: \(error.localizedDescription)"))
        }
    }
    
    private let remove_callback : lcb_RESPCALLBACK = {
        (instance, cbtype, rb) -> Void in
        // If we have no callback, we don't need to do anything else
        guard let callback = rb?.pointee.cookie,
            let uuid = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? String,
            let completion = Bucket.callbacks[uuid]else {
                return
        }
        
        //Clean up our callback.
        Bucket.callbacks.removeValue(forKey: uuid)
        
        if let err = rb?.pointee.rc, err != LCB_SUCCESS {
            completion(OperationResult.Error(Bucket.lcb_errortext(instance,err)))
            return
        }
        
        guard let response = rb?.pointee else {
            completion(OperationResult.Error("Success with No response found"))
            return
        }
        
        completion(OperationResult.Success(value:nil, cas: response.cas))


    }
    // What is in respcallback 
    // http://docs.couchbase.com/sdk-api/couchbase-c-client-2.7.3/group__lcb-kv-api.html#structlcb___r_e_s_p_b_a_s_e
    private let set_callback:lcb_RESPCALLBACK = {
        (instance, cbtype, rb) -> Void in
        
        // If we have no callback, we don't need to do anything else
        guard let callback = rb?.pointee.cookie,
            let uuid = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? String,
            let completion = Bucket.callbacks[uuid]else {
            return
        }
        
        //Clean up our callback.
        Bucket.callbacks.removeValue(forKey: uuid)
        
        if let err = rb?.pointee.rc, err != LCB_SUCCESS {
            completion(OperationResult.Error(Bucket.lcb_errortext(instance,err)))
            return
        }
        
        guard let response = rb?.pointee else {
            completion(OperationResult.Error("Success with No response found"))
            return
        }
        
        completion(OperationResult.Success(value:nil, cas: response.cas))
    }
    
    
    /// Default Bucket initializer
    ///
    /// - Parameters:
    ///   - name: bucket name
    ///   - connectionString: format of couchbase://ip1,dns2,ip3/bucketname
    ///   - password: if provided will attempt SAML auth using password
    /// - Throws: CouchbaseError.FailedInit if connection fails
    init(bucketName name:String, connectionString: String, password:String?) throws {
        self.name = name
        self.password = password
        self.userName = name
        
        var cropts:lcb_create_st = lcb_create_st()
        cropts.version = 3;
        cropts.v.v3.connstr = (connectionString as NSString).utf8String //NSString is used to interop with C
        
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
        lcb_set_get_callback(self.instance, get_callback)
        //lcb_install_callback3(self.instance, Int32(LCB_CALLBACK_GET.rawValue), get_callback);
        lcb_install_callback3(self.instance, Int32(LCB_CALLBACK_STORE.rawValue), set_callback);
        lcb_install_callback3(self.instance, Int32(LCB_CALLBACK_REMOVE.rawValue), remove_callback)
    }
    
    
    /// Rather than setting the contents of the entire document, take the value specified and append it to the existing
    /// document value.
    ///
    /// - Parameters:
    ///   - key: Document Key
    ///   - value: String value to append
    ///   - options: options for the insert operation
    ///   - completion: Callback that will be called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func append(key:String, value:String, options:Options = InsertOptions(), completion: @escaping OpCallback ) throws {
        ///TODO: acknowledge options
        
        var storeOptions = StoreOptions()
        storeOptions.dataTypeFlags = .Json //Encoder should eventually handle this
        storeOptions.operation = .Append
        storeOptions.expiry = options.expiry
        
        var cmd  = createStoreCMD(storeOptions, key: key)
        LCB_CMD_SET_VALUE(&cmd, value, value.utf8.count)
        
        try self.invokeStore(cmd: &cmd, callback: completion)
    }

    
    /// Increments or decrements a key's numeric value
    ///
    /// - Parameters:
    ///   - key: Document Key
    ///   - delta: The amount to add or subtract from the coutner value.
    ///   - options: options for the counter operation
    ///   - completion: callback which is called when the operation completes.
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func counter(key:String, delta:Int64, options:CounterOptions?, completion: @escaping OpCallback) throws {
        var ccmd = lcb_CMDCOUNTER()
        ccmd.key.type = LCB_KV_COPY
        ccmd.key.contig.bytes = UnsafeRawPointer((key as NSString).utf8String!)
        ccmd.key.contig.nbytes = key.utf8.count

        if let opts = options {
            ccmd.exptime = lcb_U32(opts.expiry)
            ccmd.delta = delta
            if let initial = opts.initial {
                ccmd.initial = lcb_U64(initial)
                ccmd.create = 1
            }
        }
        
        let uuid = storeCallback(callback: completion)
        let retainedCookie = Unmanaged<AnyObject>.passRetained(uuid as AnyObject)
        
        var err:lcb_error_t
        err = lcb_counter3(instance, retainedCookie.toOpaque(), &ccmd)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            let message = Bucket.lcb_errortext(instance, err)
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
        
        let uuid = storeCallback(callback:completion)
        let retainedCookie = Unmanaged<AnyObject>.passRetained(uuid as AnyObject)

        var err:lcb_error_t
        err = lcb_rget3(instance, retainedCookie.toOpaque(), &getRCMD)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            let message = Bucket.lcb_errortext(instance, err)
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
    public func insert(key:String, value:Any, options:Options = InsertOptions(), completion: @escaping OpCallback ) throws {
        ///TODO: acknowledge options
        //eventually use a supplied encoder?
        guard let jsonString = try encodeValue(value: value) else {
            throw CouchbaseError.FailedSerialization("value provided is not in a proper format to be serialized")
        }
        var storeOptions = StoreOptions()
        storeOptions.dataTypeFlags = .Json //Encoder should eventually handle this
        storeOptions.operation = .Insert
        storeOptions.expiry = options.expiry
        
        var cmd  = createStoreCMD(storeOptions, key: key)
        LCB_CMD_SET_VALUE(&cmd, jsonString, jsonString.utf8.count)
        
        try self.invokeStore(cmd: &cmd, callback: completion)
    }
    
    
    /// Deletes a document from the server
    ///
    /// - Parameters:
    ///   - key: Document Key
    ///   - options: options for the remove operation
    ///   - completion: Callback which is called on operation completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func remove(key:String, options:RemoveOptions?, completion: @escaping OpCallback) throws {
        var rCMD = lcb_CMDREMOVE()
        rCMD.key.type = LCB_KV_COPY
        rCMD.key.contig.bytes = UnsafeRawPointer((key as NSString).utf8String!)
        rCMD.key.contig.nbytes = key.utf8.count
        
        if let opts = options {
            rCMD.cas = opts.cas
        }
        
        let uuid = storeCallback(callback: completion)
        let retainedCookie = Unmanaged<AnyObject>.passRetained(uuid as AnyObject)
        
        var err:lcb_error_t
        err = lcb_remove3(instance, retainedCookie.toOpaque(), &rCMD)
        
        if (err != LCB_SUCCESS) {
            let message = Bucket.lcb_errortext(instance, err)
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
    public func replace(key:String, value:Any, options:ReplaceOptions = ReplaceOptions(), completion: @escaping OpCallback ) throws {
        ///TODO: acknowledge options
        //eventually use a supplied encoder?
        guard let jsonString = try encodeValue(value: value) else {
            throw CouchbaseError.FailedSerialization("value provided is not in a proper format to be serialized")
        }
        var storeOptions = StoreOptions()
        storeOptions.dataTypeFlags = .Json //Encoder should eventually handle this
        storeOptions.operation = .Upsert
        storeOptions.expiry = options.expiry
        
        var cmd  = createStoreCMD(storeOptions, key: key)
        LCB_CMD_SET_VALUE(&cmd, jsonString, jsonString.utf8.count)
        
        try self.invokeStore(cmd: &cmd, callback: completion)
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
        
        let uuid = storeCallback(callback: completion)
        let retainedCookie = Unmanaged<AnyObject>.passRetained(uuid as AnyObject)
        
        var err:lcb_error_t
        err = lcb_touch3(instance, retainedCookie.toOpaque(), &cmd)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            let message = Bucket.lcb_errortext(instance, err)
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
        ///TODO: acknowledge options
        //eventually use a supplied encoder?
        
        var cmd  = lcb_CMDUNLOCK()
        cmd.cas = cas
        LCB_CMD_SET_KEY(&cmd, key,key.utf8.count)
        
        let uuid = storeCallback(callback: completion)
        let retainedCookie = Unmanaged<AnyObject>.passRetained(uuid as AnyObject)
        
        var err:lcb_error_t
        err = lcb_unlock3(instance, retainedCookie.toOpaque(), &cmd)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            let message = Bucket.lcb_errortext(instance, err)
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
    public func upsert(key:String, value:Any, options:Options = UpsertOptions(), completion: @escaping OpCallback ) throws {
        ///TODO: acknowledge options
        //eventually use a supplied encoder?
        guard let jsonString = try encodeValue(value: value) else {
            throw CouchbaseError.FailedSerialization("value provided is not in a proper format to be serialized")
        }
        var storeOptions = StoreOptions()
        storeOptions.dataTypeFlags = .Json //Encoder should eventually handle this
        storeOptions.operation = .Upsert
        storeOptions.expiry = options.expiry
        
        var cmd  = createStoreCMD(storeOptions, key: key)
        LCB_CMD_SET_VALUE(&cmd, jsonString, jsonString.utf8.count)
        
        try self.invokeStore(cmd: &cmd, callback: completion)
    }

    
    
    // - MARK: Private helpers
    
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
    
    fileprivate func invokeGet(cmd: inout lcb_CMDGET, callback:@escaping OpCallback) throws {
        let uuid = storeCallback(callback:callback)
        let retainedCookie = Unmanaged<AnyObject>.passRetained(uuid as AnyObject)
        
        var err:lcb_error_t
        err = lcb_get3(instance, retainedCookie.toOpaque(), &cmd)
        
        if (err != LCB_SUCCESS) {
            let message = Bucket.lcb_errortext(instance, err)
            throw CouchbaseError.FailedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        lcb_wait(instance); // get_callback is invoked here
    }
    
    fileprivate func createStoreCMD(_ options:StoreOptions, key:String) -> lcb_CMDSTORE {
        var storeCMD = lcb_CMDSTORE()
        storeCMD.cas = options.cas
        storeCMD.cmdflags = options.cmdflags
        storeCMD.operation = options.operation.toLcbType()
        storeCMD.flags = options.dataTypeFlags.rawValue
        
        LCB_CMD_SET_KEY(&storeCMD, key, key.utf8.count)
        return storeCMD
    }
    
    fileprivate func invokeStore(cmd: inout lcb_CMDSTORE, callback: @escaping OpCallback) throws {
        
        let uuid = storeCallback(callback: callback)
        let retainedCookie = Unmanaged<AnyObject>.passRetained(uuid as AnyObject)
        
        var err:lcb_error_t
        err = lcb_store3(instance, retainedCookie.toOpaque(), &cmd)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            let message = Bucket.lcb_errortext(instance, err)
            throw CouchbaseError.FailedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        lcb_wait(instance); // set_callback is invoked here

    }
    
    fileprivate func storeCallback(callback:@escaping(OperationResult)->()) -> String {
        let uuid = UUID().uuidString
        Bucket.callbacks[uuid] = callback
        return uuid
    }
    
    fileprivate func encodeValue(value:Any) throws -> String? {
        return String(data: try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted), encoding:.utf8)
        
    }
    
    ///May want to move this guy somewhere more accessible later 
    ///TODO:
    fileprivate static func lcb_errortext(_ instance:lcb_t?, _ error: lcb_error_t) -> String {
        if let instance = instance,
            let errorMessage = lcb_strerror(instance,error),
            let message = String(utf8String:errorMessage) {
            return message
        }
        return "Failed with unknown error: \(error)"
    }
    
}
