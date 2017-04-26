//
//  Options.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/25/17.
//
//

import Foundation

public protocol Options {
    var expiry : Int32 {get set}
    var persistTo : Int32 {get set}
    var replicateTo : Int32 {get set}
}

public protocol CASOption {
    var cas : UInt64 {get set}
}

public struct ReplaceOptions : Options, CASOption {
    public var cas: UInt64

    public var replicateTo: Int32 = 0
    public var persistTo: Int32 = 0
    public var expiry: Int32 = 0
}

public struct InsertOptions : Options {
    public var persistTo: Int32 = 0
    public var expiry: Int32 = 0
    public var replicateTo: Int32 = 0
}

public struct GetOptions {
    public var expiry : UInt32 = 0
    public var lock : Bool = false
    public var cas : UInt64 = 0
    public var cmdflags : UInt32 = 0
}