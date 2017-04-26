//
//  DataFormat.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/26/17.
//
//

import Foundation
public enum DataFormat : UInt32 {
    case Reserved = 0x00000000
    case Private = 0x01000000
    case Json = 0x02000000
    case Binary = 0x03000000
    case String = 0x04000000
}
