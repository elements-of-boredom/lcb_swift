//
//  N1qlQueryResponse.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/21/17.
//
//

import Foundation

public enum N1QLQueryResult {
    case Error(String)
    case Success(meta:Any?, rows:[Any])
}
