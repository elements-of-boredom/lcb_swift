//
//  Bucket+N1QL.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/10/17.
//
//

import Foundation
import libcouchbase

extension Bucket {
    // - MARK: N1QL Query
    
    public func n1qlQuery(query:String, params:[String], completion:@escaping N1QLCallback) throws {
        let n1qlQuery = try N1QLQuery(statement: query, params:params)
        try self.n1qlQuery(query: n1qlQuery, completion: completion)
    }
    
    public func n1qlQuery(query:String, params:[String:Any], completion:@escaping N1QLCallback) throws {
        let n1qlQuery = try N1QLQuery(statement: query, namedParams:params)
        try self.n1qlQuery(query: n1qlQuery, completion: completion)
    }
    
    
    /// Executes a previously prepared n1qlQuery object
    ///
    /// - Parameters:
    ///   - query: Query object to execute
    ///   - completion: N1QLCallback which is called upon completion
    /// - Throws: CouchbaseError.FailedOperationSchedule
    public func n1qlQuery(query:N1QLQuery, completion:@escaping N1QLCallback) throws {
        
        var n1CMD = lcb_CMDN1QL()
        var err : lcb_error_t
        
        let statement = query.query()
        n1CMD.query = statement.utf8String
        n1CMD.nquery = statement.utf8.count
        
        if !query.isAdHoc {
            n1CMD.cmdflags |= UInt32(LCB_CMDN1QL_F_PREPCACHE)
        }
        
        n1CMD.content_type = "application/json".utf8String
        n1CMD.callback = BucketCallbacks.n1ql_row_callback
        
        let delegate = N1QLCallbackDelegate()
        delegate.callback = completion
        
        let retainedCookie = Unmanaged.passRetained(delegate)
        
        err = lcb_n1ql_query(instance, retainedCookie.toOpaque(), &n1CMD)
        if (err != LCB_SUCCESS) {
            let message = lcb_errortext(instance, err)
            throw CouchbaseError.FailedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        lcb_wait(instance);
        
    }

}
