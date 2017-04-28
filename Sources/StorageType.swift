//
//  StorageType.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/28/17.
//
//

import Foundation
import libcouchbase

public enum StorageOperation {
    case Upsert // LCB_SET
    case Insert // LCB_ADD
    case Append // LCB_APPEND
    case Prepend // LCB_PREPEND
    case Replace //LCB_REPLACE
    
    internal func toLcbType() -> lcb_storage_t {
        switch self {
        case .Upsert:
            return LCB_SET
        case .Insert:
            return LCB_ADD
        case .Append:
            return LCB_APPEND
        case .Prepend:
            return LCB_PREPEND
        case .Replace:
            return LCB_REPLACE
        }
    }
}
