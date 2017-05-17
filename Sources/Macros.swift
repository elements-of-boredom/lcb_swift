//
//  Macros.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/25/17.
//
//

import Foundation
import libcouchbase

// Swift does not expose Complex Macro's from C.
// This means we can either recreate the behavior inline, OR
// create some global functions that mirror the macro's behavior
// which is what we are going to do here

/// We have to make two of these because swift doesn't recognize C structs that get defined from
/// complex macros
func LCB_CMD_SET_KEY(_ cmd: inout lcb_CMDGET, _ key: String, _ len: Int) {
    cmd.key.type = LCB_KV_COPY
    cmd.key.contig.bytes = key.rawUTF8String
    cmd.key.contig.nbytes = len

}
func LCB_CMD_SET_KEY(_ cmd: inout lcb_CMDSTORE, _ key: String, _ len: Int) {
    cmd.key.type = LCB_KV_COPY
    cmd.key.contig.bytes = key.rawUTF8String
    cmd.key.contig.nbytes = len
}

func LCB_CMD_SET_KEY(_ cmd: inout lcb_CMDUNLOCK, _ key: String, _ len: Int) {
    cmd.key.type = LCB_KV_COPY
    cmd.key.contig.bytes = key.rawUTF8String
    cmd.key.contig.nbytes = len
}


/// Pulls the internal error string from a libcouchbase error code
///
/// - Parameters:
///   - instance: libcouchbase instance
///   - error: error returned from libcouchbase
/// - Returns: string representing the known error.
func lcb_errortext(_ instance: lcb_t?, _ error: lcb_error_t) -> String {
    if let instance = instance,
        let errorMessage = lcb_strerror(instance, error),
        let message = String(utf8String:errorMessage) {
        return "\(error.rawValue) - \(message)"
    }
    return "Failed with unknown error: \(error)"
}

/// Helper to wrap the memory unsafe String initialization required to pull most strings from libcoucbase callbacks
///
/// - Parameters:
///   - value: Pointer to a memory offset to begin reading
///   - len: bytes count to read
/// - Returns: UTF8 string from the bytes read.
func lcb_string(value: UnsafePointer<Int8>!, len: Int) -> String? {
    return String(bytesNoCopy:UnsafeMutableRawPointer(mutating:value), length:len, encoding:.utf8, freeWhenDone:false)
}

/// Helper to wrap the memory unsafe String initialization required to pull most strings from libcoucbase callbacks
///
/// - Parameters:
///   - value: Pointer to a memory offset to begin reading
///   - len: bytes count to read
/// - Returns: UTF8 string from the bytes read.
func lcb_string(value: UnsafeRawPointer, len: Int) -> String? {
    return String(bytesNoCopy:UnsafeMutableRawPointer(mutating:value), length:len, encoding:.utf8, freeWhenDone:false)
}
