//
//  LCBSwiftError.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/9/17.
//
//

import Foundation
public enum LCBSwiftError : Error {
    case InvalidConnectionString(String)
    case InvalidQueryParameters(String)
    
    //Used for items in progress or waiting for definition
    case NotImplemented(String)
}
