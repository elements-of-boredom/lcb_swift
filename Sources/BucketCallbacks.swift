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
    static let getCallback: lcb_get_callback = {
        (instance, cookie, err, resp) -> Void in

        // If we have no callback, we don't need to do anything else
        guard let callback = cookie,
            let wrapper = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? CallbackDelegate,
            let completion = wrapper.callback else {
                return
        }

        if err != LCB_SUCCESS {
            completion(OperationResult.error(lcb_errortext(instance, err)))
            return
        }

        guard let response = resp?.pointee.v.v0 else {
            completion(OperationResult.error("Success with No response found"))
            return
        }
        
        //Eventually handle decoding centralized to share w/ ViewQuery
        
        let bytes = Data(bytes:response.bytes, count:response.nbytes)
        do {
            var json = try Bucket.transcoder.decode(value: bytes)
            completion(OperationResult.success(value: json, cas: response.cas))
        } catch {
            if response.cas != 0 {
                completion(OperationResult.success(value:bytes, cas:response.cas))
                return
            }
            completion(OperationResult.error("Error attempting to create the response document"))
        }
    }

    static let removeCallback: lcb_RESPCALLBACK = {
        (instance, cbtype, rb) -> Void in
        // If we have no callback, we don't need to do anything else
        guard let callback = rb?.pointee.cookie,
            let wrapper = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? CallbackDelegate,
            let completion = wrapper.callback else {
                return
        }

        if let err = rb?.pointee.rc, err != LCB_SUCCESS {
            completion(OperationResult.error(lcb_errortext(instance, err)))
            return
        }

        guard let response = rb?.pointee else {
            completion(OperationResult.error("Success with No response found"))
            return
        }

        completion(OperationResult.success(value:nil, cas: response.cas))

    }
    // What is in respcallback
    // http://docs.couchbase.com/sdk-api/couchbase-c-client-2.7.3/group__lcb-kv-api.html#structlcb___r_e_s_p_b_a_s_e
    static let setCallback: lcb_RESPCALLBACK = {
        (instance, cbtype, rb) -> Void in
        // If we have no callback, we don't need to do anything else
        guard let callback = rb?.pointee.cookie,
            let lcb = instance, // If we don't have an instance thats a problem
            let delegate = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? CallbackDelegate,
            let completion = delegate.callback else {
                return
        }

        if let err = rb?.pointee.rc, err != LCB_SUCCESS {
            completion(OperationResult.error(lcb_errortext(instance, err)))
            return
        }

        guard let response = rb?.pointee else {
            completion(OperationResult.error("Success with No response found"))
            return
        }
        
        //If we have an endurance requirement, Endure
        if delegate.persistTo > 0 || delegate.replicateTo > 0 {
            Bucket.endure(instance:lcb, response:response, delegate:delegate)
            return
        }
        
        //Counter's need to return the new value.
        if UInt32(cbtype) == LCB_CALLBACK_COUNTER.rawValue {
            rb?.withMemoryRebound(to:lcb_RESPCOUNTER.self, capacity:1) { ptr in
                completion(OperationResult.success(value: ptr.pointee.value, cas: response.cas))
            }
            return
        }
        completion(OperationResult.success(value:nil, cas: response.cas))

    }
    
    static let n1qlRowCallback: lcb_N1QLCALLBACK = {
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
                    if let result = try? Bucket.transcoder.decode(value:data) {
                        completion(N1QLQueryResult.queryFailed(result))
                        return
                    }
                    completion(N1QLQueryResult.error("Unable to handle error from server:\n'\(data)'"))
                }
            } else {
                //Meta string parse
                var meta : Any?
                if let result = try? Bucket.transcoder.decode(value:Data(bytes: response.row, count: response.nrow)) {
                    meta = result
                }
                completion(N1QLQueryResult.success(meta:meta, rows:delegate.rows))
            }

        } else {
            let value = lcb_string(value:response.row, len:response.nrow)!
            if let result = try? Bucket.transcoder.decode(value:value) {
                delegate.rows.append(result)
            }
        }
    }
    
    static let viewQueryCallback: lcb_VIEWQUERYCALLBACK = {
        (instance, cbtype, row) -> Void in
        
        // If we have no callback, we don't need to do anything else
        guard let response = row?.pointee,
            let callback = response.cookie,
            let lcb = instance, // If we don't have an instance thats a problem
            let delegate = Unmanaged<AnyObject>.fromOpaque(callback).takeUnretainedValue() as? ViewQueryCallbackDelegate,
            let completion = delegate.callback else {
                return
        }
        
        let viewRow = ViewQueryRow()
        
        //When we get the final response
        if (UInt32(response.rflags) & LCB_RESP_F_FINAL.rawValue) != 0 {
            //Claim our delegate using RetainedVavlue to prevent leaks.
            _ = Unmanaged<AnyObject>.fromOpaque(callback).takeRetainedValue() as? ViewQueryCallbackDelegate
            var dataResult: String?
            if response.rc != LCB_SUCCESS {
                if let htresp = response.htresp, let body = htresp.pointee.body {
                    if let dataResult = lcb_string(value:htresp.pointee.body, len:htresp.pointee.nbody), dataResult.utf8.count > 0 {
                        completion(ViewQueryResult.error(dataResult))
                    } else {
                        completion(ViewQueryResult.error(lcb_errortext(instance, response.rc)))
                    }
                }
            } else {
                if let meta = lcb_string(value:response.value, len:response.nvalue) {
                    dataResult = meta
                }
            }
            
            var meta: ViewQueryMeta?
            if let dr = dataResult, let result = try? Bucket.transcoder.decode(value:dr), let dict = result as? [String:Any] {
                meta = try? ViewQueryMeta(dict: dict)
            }
            completion(ViewQueryResult.success(delegate.rows, meta))
            return
        }
        
        //Always exists. When we are in Final its Meta data, otherwise...unsure
        if let value = response.value, let key = response.key {
            let value = lcb_string(value:response.value, len:response.nvalue)!
            let key = lcb_string(value:response.key, len:response.nkey)!
            viewRow.key = key
            viewRow.value = value
        }
        
        if response.ngeometry > 0, let geo = lcb_string(value:response.geometry, len:response.ngeometry) {
            if let result = try? Bucket.transcoder.decode(value:geo) {
                viewRow.geometry = result
            } else {
                viewRow.errors = geo
            }
        }
        
        //Get the document id, and its body if specified.
        if let docid = response.docid, let docId = lcb_string(value:response.docid, len:response.ndocid) {
            viewRow.docId = docId
            
            if let docresp = response.docresp {
                if docresp.pointee.rc == LCB_SUCCESS {
                    let bytes = Data(bytes:docresp.pointee.value, count:docresp.pointee.nvalue)
                    do {
                        var json = try Bucket.transcoder.decode(value: bytes)
                        viewRow.doc = json
                    } catch {
                        viewRow.doc = bytes
                    }

                }
            }
        }
        delegate.rows.append(viewRow)
    }

}
