//
//  ViewQueryRow.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/15/17.
//
//

import Foundation
public class ViewQueryRow {
    
    /// key emitted by the view
    var key: String!
    
    /// value emitted by the view
    var value: String!
    
    /// If this is a spatial view, the GeoJSON geometry fields will be here
    var geometry : Any?
    
    /// Document ID (i.e. memcached key) associated with this row
    var docId: String!
    
    /// If include_docs was true, this will contain the document
    var doc:Any?
    
    /// Errors from the attempt to get the row.
    var errors: String?
}
