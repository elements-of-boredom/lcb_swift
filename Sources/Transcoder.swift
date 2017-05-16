//
//  Transcoder.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/16/17.
//
//

import Foundation
public class Transcoder {
    
    /// Encodes an encodable value into a JSON string
    ///
    /// - Parameter value: value attempting to be encoded
    /// - Returns: JSON encoded string.
    /// - Throws: When the value cannot be encoded, or if during encoding there is an error
    internal func encode(value:Any) throws -> String? {
        if JSONSerialization.isValidJSONObject(value) {
            return String(data: try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted), encoding:.utf8)
        }
        throw CouchbaseError.failedSerialization("Value provided is not in a format that can be json serialized")
        
    }
    
    /// decodes a JSON string into a json object (Any)-> [String:Any]
    /// we wrap all the work in an autoreleasepool because
    /// both String.data(using:), AND .jsonObject leak memory at a questionable rate.
    ///
    /// - Parameter value: json string to decode
    /// - Returns: Returns a Foundation object from given JSON data.
    /// - Throws: exceptions
    internal func decode(value: String) throws -> Any {
        return try autoreleasepool {
            if let value = value.data(using: .utf8) {
                return try JSONSerialization.jsonObject(with: value, options: [])
            }
            throw LCBSwiftError.transcodeAttemptFailed(value)
        }
    }
    
    /// decodes bytes into a json object (Any) -> [String:Any]
    /// we wrap the work in an autorelease pool because .jsonObject leaks memory
    ///
    /// - Parameter value: bytes to decode to a json object
    /// - Returns: a foundation object from given JSON data
    /// - Throws: exceptions
    internal func decode(value: Data) throws -> Any {
        return try autoreleasepool {
            return try JSONSerialization.jsonObject(with: value, options: [])
        }
    }
}
