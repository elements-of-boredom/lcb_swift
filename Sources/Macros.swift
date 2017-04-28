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
func LCB_CMD_SET_KEY(_ cmd: inout lcb_CMDGET, _ key :String, _ len: Int) {
    cmd.key.type = LCB_KV_COPY
    cmd.key.contig.bytes = UnsafeRawPointer((key as NSString).utf8String!)
    cmd.key.contig.nbytes = len

}
func LCB_CMD_SET_KEY(_ cmd: inout lcb_CMDSTORE, _ key :String, _ len: Int) {
    cmd.key.type = LCB_KV_COPY
    cmd.key.contig.bytes = UnsafeRawPointer((key as NSString).utf8String!)
    cmd.key.contig.nbytes = len
}

func LCB_CMD_SET_KEY(_ cmd: inout lcb_CMDUNLOCK, _ key :String, _ len: Int) {
    cmd.key.type = LCB_KV_COPY
    cmd.key.contig.bytes = UnsafeRawPointer((key as NSString).utf8String!)
    cmd.key.contig.nbytes = len
}

func LCB_CMD_SET_VALUE(_ cmd: inout lcb_CMDSTORE, _ value: String, _ len: Int) {
    cmd.value.vtype = LCB_KV_COPY
    cmd.value.u_buf.contig.bytes = UnsafeRawPointer((value as NSString).utf8String!)
    cmd.value.u_buf.contig.nbytes = len
}
