//
//  ViewQueryResult.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/12/17.
//
//

import Foundation
public enum ViewQueryResult {
    case success([ViewQueryRow]?, ViewQueryMeta?)
    case error(String)
    
}
