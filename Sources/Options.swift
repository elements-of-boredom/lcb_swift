//
//  Options.swift
//  lcb_swift
//
//  Created by Greg Williams on 4/25/17.
//
//

import Foundation


/// Sooo nothing going on in this file is "Ok". We'll need to fix it
/// TODO:

public struct GetOptions {
    public var expiry : UInt32 = 0
    public var lock : Bool = false
    public var cas : UInt64 = 0
    public var cmdflags : UInt32 = 0
}

public struct StoreOptions {
    public var persistTo : Int16 = 0
    public var replicateTo : Int16 = 0
    public var expiry : Int32 = 0
    public var cas : UInt64 = 0
}

internal struct CmdOptions {
    public var operation : StorageOperation = .Upsert
    public var dataTypeFlags : DataFormat = .Json
    public var cas : UInt64 = 0
    public var expiry : Int32 = 0
    public var cmdflags : UInt32 = 0
    public var persistTo : Int16 = 0
    public var replicateTo : Int16 = 0
    
}
