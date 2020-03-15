//
//  Function.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

/// 方法对象
public struct Method {
    enum MethodType {
        case none
        case native
        case script
        case call
    }
    
    public typealias NativeFnObject = (_ virtual: Virtual, _ args:inout [Value]) -> Bool
    
    var type: MethodType
    var nativeImp: NativeFnObject?
    var scriptImp: ClosureObject?
    init(type: MethodType) {
        self.type = type
    }
    init(nativeImp: @escaping NativeFnObject) {
        self.init(type: .native)
        self.nativeImp = nativeImp
    }
    init(scriptImp: ClosureObject) {
        self.init(type: .script)
        self.scriptImp = scriptImp
    }
}

/// 指令流对象
public class FnObject: ObjectProtocol {
    public var header: Header
    var instrStream: [Byte]
    var constantsTable: SymbolTable<String, Any>
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
    var localIvarTable: SymbolTable<String, Any>
    var closedIvarTable: SymbolTable<String, Any>
    var next: UpvalueObject?
    init(virtual: Virtual, localIvarTable: [String: Any]) {
        self.header = Header(virtual: virtual, type: .upValue, cls: nil)
        self.localIvarTable = localIvarTable
        self.closedIvarTable = [:]
        self.next = nil
    }
}


/// 闭包对象
public class ClosureObject: ObjectProtocol {
    public var header: Header
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
    var stack: Int
    init(virtual: Virtual, closure: ClosureObject) {
        self.closure = closure
        self.stack = 0
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
