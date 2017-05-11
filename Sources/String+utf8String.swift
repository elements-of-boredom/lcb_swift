//
//  String+utf8String.swift
//  lcb_swift
//
//  Created by Greg Williams on 5/8/17.
//
//

import Foundation
extension String {
    var utf8String: UnsafePointer<Int8> {
        return UnsafePointer<Int8>((self as NSString).utf8String!)
    }

    var rawUTF8String: UnsafeRawPointer {
        return UnsafeRawPointer(self.utf8String)
    }
}
