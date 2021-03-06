//
//  CouchbaseError.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/21/17.
//
//

import Foundation

/// Description of CouchbaseError
///
/// - FailedInit: returned when initialization fails
/// - FailedConnect: connection did not succeed
/// - FailedSerialization: serialization error
public enum CouchbaseError: Error {
    case failedInit(String)
    case failedConnect(String)
    case failedOperationSchedule(String)
    //Prolly shouldn't be here unless we make this a broader error enum ///TODO:
    case failedSerialization(String)
    case failedN1QlQuery(String)
}
