//
//  Bucket+SpatialQuery.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/17/17.
//
//

import Foundation
import libcouchbase

extension Bucket {
    public func query(query: SpatialQuery, completion:@escaping ViewQueryCallback) throws {
        var vCmd = lcb_CMDVIEWQUERY()
        vCmd.ddoc = query.designDocument.utf8String
        vCmd.nddoc = query.designDocument.utf8.count
        
        vCmd.view = query.viewName.utf8String
        vCmd.nview = query.viewName.utf8.count
        
        let options = query.optionString()
        vCmd.optstr = options.utf8String
        vCmd.noptstr = options.utf8.count
        
        vCmd.cmdflags |= UInt32(LCB_CMDVIEWQUERY_F_SPATIAL)
        
        vCmd.callback = BucketCallbacks.viewQueryCallback
        
        let delegate = ViewQueryCallbackDelegate(bucket: self)
        delegate.callback = completion
        let retainedCookie = Unmanaged.passRetained(delegate)
        
        let err = lcb_view_query(instance, retainedCookie.toOpaque(), &vCmd)
        if err != LCB_SUCCESS {
            let message = lcb_errortext(instance, err)
            throw CouchbaseError.failedOperationSchedule("Couldn't schedule operation! \(message)")
        }
        
        lcb_wait(instance)
        
    }

}
