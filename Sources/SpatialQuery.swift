//
//  SpatialQuery.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/17/17.
//
//

import Foundation
public class SpatialQuery {
    let designDocument: String
    let viewName: String
    
    private var options = [String: Any]()
    
    internal init(designDocument: String, viewName: String) {
        self.designDocument = designDocument
        self.viewName = viewName
    }
    
    public static func from(designDocument: String, viewName: String) -> SpatialQuery {
        return SpatialQuery(designDocument: designDocument, viewName: viewName)
    }
    
    public func stale(_ stale: ViewIndexState) -> SpatialQuery {
        self.options["stale"] = stale.description()
        return self
    }
    
    public func skip(_ amount: Int32) -> SpatialQuery {
        self.options["skip"] = amount
        return self
    }
    
    public func limit(_ limit: Int32) -> SpatialQuery {
        self.options["limit"] = limit
        return self
    }
    
    public func options(_ options: [String:Any]) -> SpatialQuery {
        for (key, value) in options {
            self.options[key] = value
        }
        return self
    }
    
    /// Specifies a bounding box for the query to index for. The arguments
    /// represent the left, top, right and bottom edges of the bounding box
    ///
    /// - Parameters:
    ///   - left: left edge of the bounding box
    ///   - top: top edge of the bounding box
    ///   - right: right edge of the bounding box
    ///   - bottom: bottom edge of the bounding box
    /// - Returns: SpatialQuery
    public func boundingBox(left: Int, top: Int, right: Int, bottom: Int) -> SpatialQuery {
        let bbox: [Int] = [left, top, right, bottom]
        self.options["bbox"] = bbox.map { String($0) }.joined(separator:",")
        return self
    }
    
    /// Specifies a starting and ending range
    ///
    /// - Parameters:
    ///   - start: starting range to filter on
    ///   - end: ending range to filter on
    /// - Returns: SpatialQuery
    public func range(start: [Int], end: [Int]) -> SpatialQuery {
        self.options["start_range"] = start
        self.options["end_range"] = end
        return self
    }
    
    /// Builds a url querystring from the options
    ///
    /// - Returns: url query string
    func optionString() -> String {
        
        var comp = URLComponents(string: "?")!
        for (key, value) in options {
            comp.queryItems?.append(URLQueryItem(name: key, value: String(describing:value)))
        }
        
        if let query = comp.query {
            return query
        }
        return ""
    }
}
