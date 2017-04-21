//
//  Cluster.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/21/17.
//
//

import Foundation
import libcouchbase

public class Cluster {
// MARK: - PRIVATE
    private var buckets = [Bucket]()
    private let connStr:String
    private let options:CreateOptions?
    
// MARK: - PUBLIC 
    
    public convenience init() {
        self.init(connectionString: "couchbase://localhost/default",options: nil)
    }
    
    public convenience init(connectionString: String) {
        
        self.init(connectionString:connectionString, options : CreateOptions())
    }
    
    public init(connectionString : String , options : CreateOptions? ) {
        self.connStr = connectionString
        self.options = options
    }
    
    /// Sets the authenticator... maybe a property?
    public func authenticate(auther : Authenticator) {
    
    }
    
    /// return a cluster manager for performing ops on the cluster
    /// property?
    public func manager() {
    
    }
    
    public func openBucket(name:String, callback:String) throws -> Bucket{
        let bucket = try Bucket(bucketName: name, connectionString:self.connStr, password: nil)
        buckets.append(bucket)
        return bucket
    }
    /// callback needs to be a function once we figure out what it is. ///TODO
    public func openBucket(name:String, password:String, callback : String) throws -> Bucket{
        let bucket = try Bucket(bucketName: name, connectionString:self.connStr, password: password)
        buckets.append(bucket)
        return bucket
    }
    
    /// callback needs to be a function once we proceed
    public func query(of:Query, params: [String], callback: String) -> QueryResponse {
        return N1qlQueryResponse()
    }
    
    
}
