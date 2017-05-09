//
//  URL+queryItems.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/9/17.
//
//

import Foundation
extension URL {
    public var queryItems: [String: String] {
        var params = [String: String]()
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce([:], { (_, item) -> [String: String] in
                params[item.name] = item.value
                return params
            }) ?? [:]
    }
}
