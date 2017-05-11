//
//  DataFormat.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/26/17.
//
//

import Foundation
public enum DataFormat: UInt32 {
    case reserved = 0x00000000
    case lcbPrivate = 0x01000000
    case json = 0x02000000
    case binary = 0x03000000
    case string = 0x04000000
}
