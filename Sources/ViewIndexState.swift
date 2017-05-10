//
//  ViewIndexState.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/10/17.
//
//

import Foundation
public enum ViewIndexState {
    case AllowStale
    case UpdateAfter
    case UpdateBefore
    
    internal func description() -> String {
        switch self {
        case .AllowStale:
            return "ok"
        case .UpdateAfter:
            return "update_after"
        case .UpdateBefore:
            return "false"
        }
    }
}
