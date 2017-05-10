//
//  Callbacks.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/10/17.
//
//

import Foundation
import libcouchbase

internal class BucketCallbacks {
    static let get_callback:lcb_get_callback = {
        (instance, cookie, err, resp) -> Void in
        
        // If we have no callback, we don't need to do anything else
        guard let callback = cookie,
            let wrapper = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? CallbackDelegate,
            let completion = wrapper.callback else {
                return
        }
        
        if err != LCB_SUCCESS {
            completion(OperationResult.Error(lcb_errortext(instance,err)))
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
    
    static let remove_callback : lcb_RESPCALLBACK = {
        (instance, cbtype, rb) -> Void in
        // If we have no callback, we don't need to do anything else
        guard let callback = rb?.pointee.cookie,
            let wrapper = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? CallbackDelegate,
            let completion = wrapper.callback else {
                return
        }
        
        if let err = rb?.pointee.rc, err != LCB_SUCCESS {
            completion(OperationResult.Error(lcb_errortext(instance,err)))
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
    static let set_callback:lcb_RESPCALLBACK = {
        (instance, cbtype, rb) -> Void in
        print("Is endure callback: \(LCB_CALLBACK_ENDURE.rawValue == UInt32(cbtype))")
        // If we have no callback, we don't need to do anything else
        guard let callback = rb?.pointee.cookie,
            let lcb = instance, // If we don't have an instance thats a problem
            let delegate = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? CallbackDelegate,
            let completion = delegate.callback else {
                return
        }
        
        
        if let err = rb?.pointee.rc, err != LCB_SUCCESS {
            completion(OperationResult.Error(lcb_errortext(instance,err)))
            return
        }
        
        guard let response = rb?.pointee else {
            completion(OperationResult.Error("Success with No response found"))
            return
        }
        
        //No durability constraints means we can move on.
        if delegate.persistTo == 0 && delegate.replicateTo == 0 {
            completion(OperationResult.Success(value:nil, cas: response.cas))
        } else {
            Bucket.endure(instance:lcb, response:response, delegate:delegate)
        }
    }
    
    static let n1ql_row_callback: lcb_N1QLCALLBACK = {
        (instance, cbtype, resp) -> Void in
        
        guard let response = resp?.pointee,
            let callback = response.cookie,
            let lcb = instance, // If we don't have an instance thats a problem
            let delegate = Unmanaged<AnyObject>.fromOpaque(callback).takeUnretainedValue() as? N1QLCallbackDelegate,
            let completion = delegate.callback else {
                return
        }
        
        //When we get the final response
        if (UInt32(response.rflags) & LCB_RESP_F_FINAL.rawValue) != 0 {
            //Claim our delegate using RetainedVavlue to prevent leaks.
            _ = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? N1QLCallbackDelegate
            if response.rc != LCB_SUCCESS {
                //Error string parse
                if let row = response.row {
                    let data = String(utf8String:row)!
                    completion(N1QLQueryResult.Error(data))
                }
            } else {
                //Meta string parse
                let data = String(utf8String:response.row)!
                var meta : Any?
                
                if let result = try? Bucket.decodeValue(value:data) {
                    meta = result
                }
                completion(N1QLQueryResult.Success(meta:meta, rows:delegate.rows))
                
            }
            
        } else {
            let value = String(bytesNoCopy:UnsafeMutableRawPointer(mutating:response.row),length:response.nrow, encoding:.utf8, freeWhenDone:false)!
            if let result = try? Bucket.decodeValue(value:value) {
                delegate.rows.append(result)
            }
        }
    }


}
