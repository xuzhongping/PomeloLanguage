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
    
    public typealias NativeFnObject = (_ virtual: Virtual, _ args:inout [AnyValue]) -> Bool
    
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
public class FnObject: NSObject, ObjectProtocol {
    public var header: Header
    var byteStream: [Byte]
    var constantsList: [AnyValue]
    var module: ModuleObject
    var maxStackSize: Int
    var upvalueCount: Int
    var argNum: Int
    
    #if DEBUG
    var debug: FnDebug?
    #endif
    init(virtual: Virtual, module: ModuleObject, maxStackSize: Int) {
        self.header = Header(virtual: virtual, type: .function, cls: nil)
        self.module = module
        self.maxStackSize = maxStackSize
        self.byteStream = []
        self.constantsList = []
        self.upvalueCount = 0
        self.argNum = 0
    }
}


/// upvalue对象
class UpvalueObject: NSObject, ObjectProtocol {
    var header: Header
    var localVars: [AnyValue]
    var closedVars: [AnyValue]
    var next: UpvalueObject?
    init(virtual: Virtual) {
        self.header = Header(virtual: virtual, type: .upValue, cls: nil)
        self.localVars = []
        self.closedVars = []
        self.next = nil
    }
}


/// 闭包对象
public class ClosureObject: NSObject, ObjectProtocol {
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
    var stack: [AnyValue]
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
