//
//  OpResult.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/25/17.
//
//

import Foundation
public enum OperationResult {
    case error(String)
    case success(value:Any?, cas:UInt64)
}
