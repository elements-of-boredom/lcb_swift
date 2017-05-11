//
//  MultiCallbackResult.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/26/17.
//
//

import Foundation
public enum MultiCallbackResult {
    case error(String)
    case success(UInt, [String:OperationResult])
}
