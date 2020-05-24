//
//  FunctionInfo.swift
//  PomeloLanguageContainer
//
//  Created by xuzhongping on 2020/5/23.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class FnInfo: NSObject {
    public var bytes: [Byte]
    public var consts: [Value]
    public var stackCapacity: Int
    public var argNum: Int
    public var maxStackSize: Int
    public init(stackCapacity: Int) {
        self.bytes = []
        self.consts = []
        self.stackCapacity = stackCapacity
        self.argNum = 0
        self.maxStackSize = 0
    }
}

public class UpvalueInfo: NSObject {
    var value: Value
    public init(value: Value) {
        self.value = value
    }
}

public class ClosureInfo: NSObject {
    var fn: FnInfo
    var upvalues: [UpvalueInfo]
    
    public init(fn: FnInfo) {
        self.fn = fn
        self.upvalues = []
    }
}
