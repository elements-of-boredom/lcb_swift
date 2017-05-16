//
//  ViewQueryCallbackDelegate.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/12/17.
//
//

import Foundation
import libcouchbase

public typealias ViewQueryCallback = (ViewQueryResult) -> Void

public class ViewQueryCallbackDelegate {
    internal var rows = [ViewQueryRow]()
    internal var callback: ViewQueryCallback?
}
