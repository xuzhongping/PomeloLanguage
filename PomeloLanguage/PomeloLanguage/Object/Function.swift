//
//  Function.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa


/// 指令流对象
class FnObject: ObjectProtocol {
    var header: Header
    var instrStream: [Byte]
    var constantsTable: [String: Any]
    var module: ModuleObject
    var maxStackSize: uint64
    var upvalueCount: uint64
    var argCount: uint8
    
    #if DEBUG
    var debug: FnDebug?
    #endif
    init(virtual: Virtual, module: ModuleObject, maxStackSize: uint64) {
        self.header = Header(virtual: virtual, type: .function, cls: nil)
        self.module = module
        self.maxStackSize = maxStackSize
        self.instrStream = []
        self.constantsTable = [:]
        self.upvalueCount = 0
        self.argCount = 0
    }
}


/// upvalue对象
class UpvalueObject: ObjectProtocol {
    var header: Header
    var localIvarTable: [String: Any]
    var closedIvarTable: [String: Any]
    var next: UpvalueObject?
    init(virtual: Virtual, localIvarTable: [String: Any]) {
        self.header = Header(virtual: virtual, type: .upValue, cls: nil)
        self.localIvarTable = localIvarTable
        self.closedIvarTable = [:]
        self.next = nil
    }
}


/// 闭包对象
class ClosureObject: ObjectProtocol {
    var header: Header
    var fn: FnObject
    var upvalues: [UpvalueObject]
    init(virtual: Virtual, fn: FnObject) {
        self.header = Header(virtual: virtual, type: .closure, cls: nil)
        self.fn = fn
        self.upvalues = []
    }
}

/// 调用框架
class CallFrame {
    var ip: uint64
    var closure: ClosureObject
    var stack: [Any]
    init(virtual: Virtual, closure: ClosureObject) {
        self.closure = closure
        self.stack = []
        self.ip = 0
    }
}

class FnDebug {
    var name: String
    var line: Int
    init(name: String, line: Int) {
        self.name = name
        self.line = line
    }
}
