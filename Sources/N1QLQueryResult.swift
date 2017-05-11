//
//  N1qlQueryResponse.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/21/17.
//
//

import Foundation

public enum N1QLQueryResult {
    case error(String)
    case queryFailed(Any?)
    case success(meta:Any?, rows:[Any])
}
