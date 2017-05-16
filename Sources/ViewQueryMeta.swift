//
//  ViewQueryMeta.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/16/17.
//
//

import Foundation
public struct ViewQueryMeta {
    let totalRows: Int
    
    init(totalRows: Int) {
        self.totalRows = totalRows
    }
    
    init(dict: [String:Any]) throws {
        if let total_rows = dict["total_rows"] as? Int {
            totalRows = total_rows
        } else {
            throw LCBSwiftError.notImplemented("TODO: ViewQueryMeta init")
        }
    }
}
