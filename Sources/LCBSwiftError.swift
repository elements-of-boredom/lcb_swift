//
//  LCBSwiftError.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/9/17.
//
//

import Foundation
public enum LCBSwiftError: Error {
    case invalidConnectionString(String)
    case invalidQueryParameters(String)
    case transcodeAttemptFailed(String)

    //Used for items in progress or waiting for definition
    case notImplemented(String)
}
