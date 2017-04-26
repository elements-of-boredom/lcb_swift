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

public class Bucket {
    private var instance : lcb_t?
    private let name:String
    private let userName:String
    private let password:String?
    
    private static var callbacks = [String:OpCallback]()
    
    // - MARK: Members
    public let clientVersion : String = "0.1"
    public var lcbVersion : String

    
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
            if let errorMessage = lcb_strerror(instance,err),
                let message = String(utf8String:errorMessage) {
                completion(OperationResult.Error(message))
            } else{
                completion(OperationResult.Error("Failed with unknown error \(err)"))
            }
            return
        }
        
        //Early out if we can't FIND the completion callback or its badly formed.
        //Could guard all this at once, but may want to log differently?
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
            if let errorMessage = lcb_strerror(instance,err),
                let message = String(utf8String:errorMessage) {
                completion(OperationResult.Error(message))
            } else{
                completion(OperationResult.Error("Failed with unknown error \(err)"))
            }
            return
        }
        
        //Early out if we can't FIND the completion callback or its badly formed.
        //Could guard all this at once, but may want to log differently?
        guard let response = rb?.pointee else {
            completion(OperationResult.Error("Success with No response found"))
            return
        }
        
        completion(OperationResult.Success(value:nil, cas: response.cas))
    }
    
    
    init(bucketName name:String, connectionString: String, password:String?) throws {
        self.name = name
        self.password = password
        self.userName = name
        
        var cropts:lcb_create_st = lcb_create_st()
        cropts.version = 3;
        cropts.v.v3.connstr = (connectionString as NSString).utf8String //NSString is used to interop with C
        
        print(String(cString: cropts.v.v3.connstr)) //Must put parameter name cString
        
        //TODO: http://docs.couchbase.com/sdk-api/couchbase-c-client-2.4.0-beta/group___l_c_b___e_r_r_o_r_s.html
        //Actuall do something w/ the error maybe?
        var err:lcb_error_t
        err = lcb_create( &self.instance, &cropts )
        if ( err != LCB_SUCCESS ) {
            print("Couldn't create instance!")
            throw CouchbaseError.FailedInit(("Couldn't create instance"))
        }
        
        // connecting
        lcb_connect(instance)
        lcb_wait(instance)
        err = lcb_get_bootstrap_status(instance)
        if ( err != LCB_SUCCESS ) {
            print("Couldn't bootstrap!")
            throw CouchbaseError.FailedConnect("Couldn't connect to the instance")
        }
        
        //Just set it for now
        self.lcbVersion = "0.1"
        
        //register callback
        lcb_set_get_callback(self.instance, get_callback)
        //lcb_install_callback3(self.instance, Int32(LCB_CALLBACK_GET.rawValue), get_callback);
        lcb_install_callback3(self.instance, Int32(LCB_CALLBACK_STORE.rawValue), set_callback);
    }
    
    public func disconnect() {
        lcb_destroy(self.instance)
    }
    
    public func get(key:String, completion: @escaping OpCallback) {
        var getCMD = createGetCMD(GetOptions(),key:key)
        invokeGet(cmd: &getCMD, callback: completion)
        
    }
    
    public func getAndLock(key:String, lockTime:UInt32 = 15, completion: @escaping OpCallback) {
        let options = GetOptions(expiry: min(lockTime,UInt32(30)), lock: true, cas: 0, cmdflags: 0)
        var getCMD = createGetCMD(options,key:key)
        invokeGet(cmd: &getCMD, callback:completion)

    }
    
    public func getAndTouch(key:String, expiry:UInt32, completion: @escaping OpCallback) {
        let options = GetOptions(expiry: expiry, lock: false, cas: 0, cmdflags: 0)
        var getCMD = createGetCMD(options,key:key)
        invokeGet(cmd: &getCMD, callback: completion)

    }

    public func insert(key:String, value:Any, options:Options = InsertOptions(), completion: @escaping(OperationResult)->() ) throws {
        
        //eventually use a supplied encoder?
        guard let jsonString = try encodeValue(value: value) else {
            throw CouchbaseError.FailedSerialization("value provided is not in a proper format to be serialized")
        }
        
        var cmd :lcb_CMDSTORE = lcb_CMDSTORE()
        cmd.operation = LCB_SET
        LCB_CMD_SET_KEY(&cmd, key, key.utf8.count)
        LCB_CMD_SET_VALUE(&cmd, jsonString, jsonString.utf8.count)
        cmd.flags = DataFormat.Json.rawValue
        let uuid = storeCallback(callback: completion)
        let retainedCookie = Unmanaged<AnyObject>.passRetained(uuid as AnyObject)
        
        var err:lcb_error_t
        err = lcb_store3(instance, retainedCookie.toOpaque(), &cmd)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            print("Couldn't schedule get operation! \(err)");
            exit(1);
        }
        lcb_wait(instance); // set_callback is invoked here
    }
    
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
    
    fileprivate func invokeGet(cmd: inout lcb_CMDGET, callback:@escaping OpCallback) {
        let uuid = storeCallback(callback:callback)
        let retainedCookie = Unmanaged<AnyObject>.passRetained(uuid as AnyObject)
        
        var err:lcb_error_t
        err = lcb_get3(instance, retainedCookie.toOpaque(), &cmd)
        
        //Need to handle completion call here if we failed to schedule
        //or completion will never be called on failure
        if (err != LCB_SUCCESS) {
            print("Couldn't schedule get operation! \(err)");
            exit(1);
        }
        lcb_wait(instance); // get_callback is invoked here
    }
    
    fileprivate func storeCallback(callback:@escaping(OperationResult)->()) -> String {
        let uuid = UUID().uuidString
        Bucket.callbacks[uuid] = callback
        return uuid
    }
    
    fileprivate func encodeValue(value:Any) throws -> String? {
        return String(data: try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted), encoding:.utf8)
        
    }
    
}
