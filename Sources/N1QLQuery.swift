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
    public var scanConsistency : N1QLScanConsistency
    
    
    internal init(statement:String, params:[String] = [], namedParams:[String:Any] = [:], consistency:N1QLScanConsistency = .None) throws {
        self.statement = statement
        self.params = params
        self.namedParams = namedParams
        self.scanConsistency = consistency
        
        if consistency != .None {
            throw LCBSwiftError.NotImplemented("Currently only .None is acknowledged")
        }
        
        if !JSONSerialization.isValidJSONObject(namedParams) {
            throw LCBSwiftError.InvalidQueryParameters("The parameters specified are unable to be serialized to JSON")
        }
        
        
    }
    
    internal func query() -> String {
        var s :[String:Any] = ["statement":statement]
        _ = namedParams.map{ param in
            s["$\(param.key)"] = param.value
        }
        
        s["args"] = params
        
        s["scan_consistency"] = scanConsistency.description()
        
        return autoreleasepool {
            if let json = try? JSONSerialization.data(withJSONObject: s, options:[]) {
                if let content = String(data:json, encoding:.utf8) {
                    return content
                }
            }
            return ""
        }
    }
    
    
    /// Creates a N1QL query object directly from the provided query string
    ///
    /// - Parameters:
    ///   - query: The N1QL query string
    ///   - params: Array of string parameters used for positional arguments
    ///   - namedParams: Dictionary of String:Any parameters used for named parameters.
    ///     The value elements of the dictionary must be JSON serializable.
    /// - Returns: a N1QLQuery object
    /// - Throws: LCBSwiftError.InvalidQueryParameters
    public static func fromString(query:String, params:[String] = [], namedParams:[String:Any] = [:]) throws -> N1QLQuery {
        return try N1QLQuery(statement:query,params:params, namedParams:namedParams)
    }
    
}
