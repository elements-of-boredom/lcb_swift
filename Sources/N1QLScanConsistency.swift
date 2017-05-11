//
//  ScanConsitency.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/9/17.
//
//

import Foundation

/// N1QL Queries can execute through Global Secondary Indexes, or map-reduce views, however both
/// are eventually consistent with ongoing mutations.
///
/// - None: Allows the query to return data that is currently indexed. This is the default query setting.
///   This level is useful for queries which favor low latency and do not need precise and the most up-to-date information
/// - Request: Allows you to "Read your own writes", comes with slightly higher latency. Provides consistency based on a
///   scan_vector (timestamp) which is generated for you at time of Query creation.
/// - Statement: Highest consistency level, requres all mutations up to the point of the query request to be processed
///   before the query execution can start.
public enum N1QLScanConsistency {
    case none
    case request
    case statement

    internal func description() -> String {
        switch self {
        case .none:
            return "not_bounded"
        case .request:
            return "at_plus"
        case .statement:
            return "request_plus"
        }
    }
}
