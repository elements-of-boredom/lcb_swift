//
//  ViewQuery.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/10/17.
//
//

import Foundation
public class ViewQuery {

    let designDocument: String
    let viewName: String
    private let viewPath: String

    private var options = [String: Any]()

    internal init(designDocument: String, viewName: String) {
        //May not need this?
        let path = "_design/\(designDocument)/_view/\(viewName)"
        self.viewPath = path
        self.designDocument = designDocument
        self.viewName = viewName
    }

    public static func from(designDocument: String, viewName: String) -> ViewQuery {
        return ViewQuery(designDocument: designDocument, viewName: viewName)
    }

    public func skip(_ amount: Int32) -> ViewQuery {
        self.options["skip"] = amount
        return self
    }

    public func limit(_ limit: Int32) -> ViewQuery {
        self.options["limit"] = limit
        return self
    }

    public func order(_ order: ViewSortOrder) -> ViewQuery {
        self.options["descending"] = order == .descending
        return self
    }

    public func stale(_ stale: ViewIndexState) -> ViewQuery {
        self.options["stale"] = stale.description()
        return self
    }

    public func reduce(_ reduce: Bool) -> ViewQuery {
        self.options["reduce"] = reduce
        return self
    }

    public func group(_ group: Bool) -> ViewQuery {
        self.options["group"] = group
        return self
    }

    public func groupLevel(_ groupLevel: Int32) -> ViewQuery {
        self.options["group_level"] = groupLevel
        return self
    }

    public func key(_ key: String) -> ViewQuery {
        self.options["key"] = key
        return self
    }

    public func keys(_ keys: [String]) -> ViewQuery {
        self.options["keys"] = JSONStringify(value: keys)
        return self
    }

    public func range(start: [String]? = nil, end: [String]? = nil, inclusiveEnd: Bool?) -> ViewQuery {
        if let start = start {
            self.options["startkey"] = JSONStringify(value: start)
        }
        if let end = end {
            self.options["endkey"] = JSONStringify(value: end)
        }
        if let inclusive = inclusiveEnd {
            self.options["inclusive_end"] = inclusive
        }
        return self
    }

    public func idRange(start: String? = nil, end: String? = nil) -> ViewQuery {
        if let start = start {
            self.options["startkey_docid"] = start
        }
        if let end = end {
            self.options["endkey_docid"] = end
        }
        return self
    }

    public func includeDocs(_ include: Bool) -> ViewQuery {
        if !include {
            self.options.removeValue(forKey: "include_docs")
        } else {
            self.options["include_docs"] = true
        }
        return self
    }

    public func fullSet(_ fullSet: Bool) -> ViewQuery {
        if !fullSet {
            self.options.removeValue(forKey: "full_set")
        } else {
            self.options["full_set"] = true
        }
        return self
    }

    public func options(_ options: [String:Any]) -> ViewQuery {
        for (key, value) in options {
            self.options[key] = value
        }
        return self
    }

    /// Builds a url querystring from the options
    ///
    /// - Returns: url query string
    internal func optionString() -> String {

        var comp = URLComponents(string: "?")!
        for (key, value) in options {
            comp.queryItems?.append(URLQueryItem(name: key, value: String(describing:value)))
        }

        if let query = comp.query {
            return query
        }
        return ""
    }
    
    internal func isIncludeDocs() -> Bool {
        if let include = options["include_docs"] as? Bool {
            return include
        }
        return false
    }

    /// Mirrors JSON.stringify in javascript
    ///
    /// - Parameters:
    ///   - value: values to "stringify"
    ///   - prettyPrinted: return the string with "pretty" spacing
    /// - Returns: stringified object.
    private func JSONStringify(value:Any, prettyPrinted: Bool = false) -> String {
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : []
        guard JSONSerialization.isValidJSONObject(value: value) else {
            return ""
        }
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: options) else {
               return ""
        }
        guard let result = String(data:data, encoding:.utf8) else {
            return ""
        }
        return result
    }
}
