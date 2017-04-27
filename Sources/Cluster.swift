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
    
    
    /// Convenience initializer for a Cluster.
    /// Uses the default bucket at localhost, with no options
    public convenience init() {
        self.init(connectionString: "couchbase://localhost/default",options: nil)
    }
    
    
    /// Convenience initializer for a Cluster.
    /// Uses the supplied connectionString with no options
    /// expected format for connectionString is `couchbase://$HOSTS/$BUCKET?$OPTIONS`
    ///
    /// - Parameter connectionString: url-encoded connection string
    public convenience init(connectionString: String) {
        
        self.init(connectionString:connectionString, options : nil)
    }
    
    
    /// Creates a Cluster object which holds reference to the buckets it owns
    ///
    /// - Parameters:
    ///   - connectionString: url-encoded connection string
    ///   - options: additional connection options used for managaing connections
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
    
    
    /// Opens a bucket, making it available for operation requests.
    ///
    /// - Parameter name: The name of the bucket to open
    /// - Returns: an initialized bucket ready for operations
    /// - Throws: CouchbaseError.FailedInit, .FailedConnect
    public func openBucket(name:String) throws -> Bucket{
        let bucket = try Bucket(bucketName: name, connectionString:self.connStr, password: nil)
        buckets.append(bucket)
        return bucket
    }
    /// callback needs to be a function once we figure out what it is. ///TODO
    public func openBucket(name:String, password:String) throws -> Bucket{
        let bucket = try Bucket(bucketName: name, connectionString:self.connStr, password: password)
        buckets.append(bucket)
        return bucket
    }
   
    
}
