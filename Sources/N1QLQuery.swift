//
//  N1QLQuery.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/8/17.
//
//

import Foundation
public class N1QLQuery {
    public let statement:String
    public var isAdHoc : Bool = true
    public let params : [String]
    public let namedParams : [String:Any]
    public var scanConsistency : N1QLScanConsitency
    
    
    init(statement:String, params:[String] = [], namedParams:[String:Any] = [:], consistency:N1QLScanConsitency = .None) {
        self.statement = statement
        self.params = params
        self.namedParams = namedParams
        self.scanConsistency = consistency
    }
    
    public func query() -> String {
        var s :[String:Any] = ["statement":statement]
        _ = namedParams.map{ param in
            s["$\(param.key)"] = param.value
        }
        
        s["args"] = params
        
        if let json = try? JSONSerialization.data(withJSONObject: s, options:[]) {
            if let content = String(data:json, encoding:.utf8) {
                return content
            }
        }

        return ""
    }
    
}
