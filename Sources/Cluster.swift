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
    private var connStr:URL
    private let options:CreateOptions?
    
// MARK: - PUBLIC 
    
    
    /// Convenience initializer for a Cluster.
    /// Uses the default bucket at localhost, with no options
    public convenience init() throws {
        try self.init(connectionString: "couchbase://localhost/default",options: nil)
    }
    
    
    /// Convenience initializer for a Cluster.
    /// Uses the supplied connectionString with no options
    /// expected format for connectionString is `couchbase://$HOSTS/$BUCKET?$OPTIONS`
    ///
    /// - Parameter connectionString: url-encoded connection string
    public convenience init(connectionString: String) throws {
        try self.init(connectionString:connectionString, options : nil)
    }
    
    
    /// Creates a Cluster object which holds reference to the buckets it owns
    ///
    /// - Parameters:
    ///   - connectionString: url-encoded connection string
    ///   - options: additional connection options used for managaing connections
    public init(connectionString : String , options : CreateOptions? ) throws {
        guard let url = URL(string:connectionString) else {
            throw LCBSwiftError.InvalidConnectionString("'\(connectionString)' is not valid")
        }
    
        guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw LCBSwiftError.InvalidConnectionString("'\(connectionString)' is not valid")
        }
        if let items = comps.queryItems, (items.filter{$0.name == "client_string"}).count > 0 {
            throw LCBSwiftError.InvalidConnectionString("'\(connectionString)' is not valid, you may not specify a client_string")
        }
        
        //We know they are there because of the above check, no point in checking them again.
        comps.queryItems?.append(URLQueryItem(name: "client_string", value: "lcbswift/\(Bucket.clientVersion)"))
        guard let modified = comps.url else {
            throw LCBSwiftError.InvalidConnectionString("Unable to append client_string, please report this bug")
        }
        self.connStr = modified
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
        let conn = bucketConnection(name: name)
        let bucket = try Bucket(bucketName: name, connection:conn, password: nil)
        buckets.append(bucket)
        return bucket
    }
    
    
    /// Opens a bucket making it available for operation requests
    ///
    /// - Parameters:
    ///   - name: The name of the bucket to open
    ///   - password: password used to secure the bucket
    /// - Returns: Bucket
    /// - Throws: CouchbaseError.FailedInit, .FailedConnect
    public func openBucket(name:String, password:String) throws -> Bucket{
        let conn = bucketConnection(name: name)
        let bucket = try Bucket(bucketName: name, connection:conn, password: password)
        buckets.append(bucket)
        return bucket
    }
   
    
    /// Builds a connection string from the composite
    fileprivate func bucketConnection(name:String) -> URL{
        let url = connStr.deletingLastPathComponent()
                    .appendingPathComponent(name)
        
        print(url)
        return url
    }
    
}
