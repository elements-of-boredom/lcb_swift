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
    private var instance : lcb_t?
    private let name:String
    private let userName:String
    private let password:String?
 
    
    private static var callbacks = [String:(lcb_error_t?, lcb_get_resp_t?) -> ()]()
    
    // - MARK: Members
    public let clientVersion : String = "0.1"
    public var lcbVersion : String

    
    private let get_callback:lcb_get_callback = {
        (instance, cookie, err, resp) -> Void in
        let key =  Data(bytes: resp!.pointee.v.v0.key, count: resp!.pointee.v.v0.nkey)
        print("Retreived key \(String(data: key, encoding: String.Encoding.utf8)!)")
        if let callback = cookie {
            let x : String = String(cString:callback.assumingMemoryBound(to: Int8.self))
            Bucket.callbacks[x]?(err,resp?.pointee)
        }
        let bytes = Data(bytes:resp!.pointee.v.v0.bytes, count:resp!.pointee.v.v0.nbytes)
        print("Value is \(String(data: bytes , encoding: String.Encoding.utf8)!)")
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
    }
    
    public func get(key:String) {
        // Get operation
        var gcmd:lcb_get_cmd_t = lcb_get_cmd_t();
        var gcmdlist:UnsafePointer<lcb_get_cmd_t>? = withUnsafePointer(to: &gcmd) {
            UnsafePointer<lcb_get_cmd_t>($0)
        }
        gcmd.v.v0.key = UnsafeRawPointer((key as NSString).utf8String!)
        gcmd.v.v0.nkey = key.characters.count;
        let uuid = UUID().uuidString
        Bucket.callbacks[uuid] = printstuff
        err = lcb_get(instance, uuid, 1, &gcmdlist);
        if (err != LCB_SUCCESS) {
            print("Couldn't schedule get operation! \(err)");
            exit(1);
        }
        lcb_wait(instance); // get_callback is invoked here
    }
    
    private func printstuff(err:lcb_error_t?, resp: lcb_get_resp_t?) {
        print("Stuff")
        print("err:\(err)")
        print("resp:\(resp)")
    }
    
    
}
