//
//  N1QLCallbackDelegate.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/3/17.
//
//

import Foundation

public typealias N1QLCallback = (N1QLQueryResult) -> Void

/// Swift does not allow dynamic dispatch which means any function pointers
/// that we would pass into the C library can't be called in Swift later.
/// To work around this, this object will hold delegate functions to help
/// hide this annoyance from the users of the SDK. We can then pass a pointer
/// to the unmanaged retained instance of this callback through as the cookie
/// and be able to call it in Swift inside the response callbacks from libcouchbase
public class N1QLCallbackDelegate {

    internal var rows = [Any]()
    internal var callback: N1QLCallback?
}
