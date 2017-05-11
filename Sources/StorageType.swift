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
    case upsert // LCB_SET
    case insert // LCB_ADD
    case append // LCB_APPEND
    case prepend // LCB_PREPEND
    case replace //LCB_REPLACE

    internal func toLcbType() -> lcb_storage_t {
        switch self {
        case .upsert:
            return LCB_SET
        case .insert:
            return LCB_ADD
        case .append:
            return LCB_APPEND
        case .prepend:
            return LCB_PREPEND
        case .replace:
            return LCB_REPLACE
        }
    }
}
