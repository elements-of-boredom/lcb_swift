//
//  ViewIndexState.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/10/17.
//
//

import Foundation
public enum ViewIndexState {
    case allowStale
    case updateAfter
    case updateBefore

    internal func description() -> String {
        switch self {
        case .allowStale:
            return "ok"
        case .updateAfter:
            return "update_after"
        case .updateBefore:
            return "false"
        }
    }
}
