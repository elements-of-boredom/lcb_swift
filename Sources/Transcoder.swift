//
//  Transcoder.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/16/17.
//
//

import Foundation
import libcouchbase

public class Transcoder {
    private let mask: UInt32 = 0xFF000000
    
    
    /// Called from storage operations which need the user supplied value encoded. 
    /// Invokes the public encode to allow for customized overrides of the encode function,
    /// storing the result in the cmd buffer, and sets the return flags for future decode attempts
    ///
    /// - Parameters:
    ///   - cmd: <#cmd description#>
    ///   - value: <#value description#>
    /// - Throws: <#throws value description#>
    internal func encode(cmd:inout lcb_CMDSTORE, value:Any) throws {
        let (bytes, flags) = try self.encode(value:value)
        cmd.value.vtype = LCB_KV_COPY
        cmd.value.u_buf.contig.bytes = (bytes as NSData).bytes
        cmd.value.u_buf.contig.nbytes = bytes.count
        cmd.flags = flags

    }
    
    
    /// Receives a value when a storage operation is invoked that needs to be encoded for storage
    /// into couchbase.
    ///
    /// - Parameter value: value that needs encoding
    /// - Returns: Tuple of the value represented by Data, and an unsigned integer representing storage flags used for decoding the value later
    /// - Throws: LCBSwiftError.transocdeAttemptFailed,Foundation JSON exceptions
    public func encode(value: Any) throws -> (Data, UInt32) {
        if let stringValue = value as? String, let data = stringValue.data(using:.utf8) {
            return (data, DataFormat.string.rawValue)
        } else if let dataValue = value as? Data {
            return (dataValue, DataFormat.binary.rawValue)
        } else {
            if let json = try? encodeJson(value: value) {
                return (json, DataFormat.json.rawValue)
            }
        }
        throw LCBSwiftError.transcodeAttemptFailed("Invalid value type passed to encode: `\(Mirror(reflecting:value).subjectType)`")
    }
    
    /// Default decode implementation.
    ///
    /// - Parameters:
    ///   - value: value to decode
    ///   - flags: Couchbase flags defining the type of data
    /// - Returns: decoded data.
    public func decode(value: Data, flags: UInt32) -> Any {
        let format = flags & mask
        
        switch format {
        case DataFormat.json.rawValue:
            do {
                return try self.decodeJson(value:value)
            } catch {
                //return raw if parse fails.
                return value
            }
        case DataFormat.binary.rawValue:
            return value
        case DataFormat.string.rawValue:
            return String(data:value, encoding:.utf8)!
        case DataFormat.reserved.rawValue: //Append/prepend
            return String(data:value, encoding:.utf8)!
        //Don't know where or how this is used, assume the user knows what to do with it.
        case DataFormat.lcbPrivate.rawValue:
            return value
        //Exhaustive case statement required because our enum extends UInt32
        default:
            return value
        }
    }
    
    /// Encodes an encodable value into a JSON string
    ///
    /// - Parameter value: value attempting to be encoded
    /// - Returns: JSON encoded string.
    /// - Throws: When the value cannot be encoded, or if during encoding there is an error
    public func encodeJson(value:Any) throws -> Data {
        if JSONSerialization.isValidJSONObject(value) {
            return try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
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
    public func decodeJson(value: String) throws -> Any {
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
    public func decodeJson(value: Data) throws -> Any {
        return try autoreleasepool {
            return try JSONSerialization.jsonObject(with: value, options: [])
        }
    }
}
