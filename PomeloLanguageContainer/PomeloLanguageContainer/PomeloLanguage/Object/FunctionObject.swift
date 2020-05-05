//
//  Function.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

/// 编译时和运行时结构
/// 方法对象
public class Method {
    enum MethodType {
        case none
        /// 原生函数
        case native
        /// 脚本方法
        case script
        /// 脚本函数
        case call
    }
    
    public typealias NativeFnObject = (_ virtual: Virtual,_ stack: inout [AnyValue], _ argsStart: Index) -> Bool
    
    var type: MethodType
    var nativeImp: NativeFnObject?
    var scriptImp: ClosureObject?
    
    init(type: MethodType) {
        self.type = type
    }
    
    convenience init(nativeImp: @escaping NativeFnObject) {
        self.init(type: .native)
        self.nativeImp = nativeImp
    }
    
    convenience init(scriptImp: ClosureObject) {
        self.init(type: .script)
        self.scriptImp = scriptImp
    }
}

/// 编译时和运行时结构
/// 指令流对象
public class FnObject: BaseObject {
    public var byteStream: [Byte]
    var constants: [AnyValue]
    var module: ModuleObject
    
    var maxStackSize: Int
    var upvalueNum: Int
    var argNum: Int
    
    #if DEBUG
    var debug: FnDebug?
    #endif
    
    init(virtual: Virtual, module: ModuleObject, maxStackSize: Int) {
        self.module = module
        self.maxStackSize = maxStackSize
        self.byteStream = []
        self.constants = []
        self.upvalueNum = 0
        self.argNum = 0
        super.init(virtual: virtual, type: .function, cls: nil)
    }
}

/// 运行时结构
/// upvalue对象
class UpvalueObject: BaseObject {
    var localVarIndex: Index?
    var closedUpvalue: AnyValue?
    init(virtual: Virtual) {
        super.init(virtual: virtual, type: .upValue, cls: nil)
    }
}

/// 编译时和运行时结构
/// 闭包对象，指代定义在一个编译单元内的另一个编译单元
public class ClosureObject: BaseObject {
    var fn: FnObject
    var upvalues: [UpvalueObject]
    
    init(virtual: Virtual, fn: FnObject) {
        self.fn = fn
        self.upvalues = []
        super.init(virtual: virtual, type: .closure, cls: nil)
    }
}

/// 运行时结构
/// 调用框架
class CallFrame {
    var ip: Index
    
    /// 栈帧中运行的函数，可是函数有可能有upvalue，故用闭包对象兼容
    var closure: ClosureObject
    
    /// 栈帧中运行的函数对应的运行时栈，其存在于线程的运行时栈中，故此处指代在所在线程运行时栈中的索引为自己的栈开始处
    var stackStart: Index
    init(closure: ClosureObject, stackStart: Index, ip: Index) {
        self.closure = closure
        self.stackStart = stackStart
        self.ip = ip
    }
}

/// 编译时和运行时结构
class FnDebug {
    var name: String
    var line: Int
    init(name: String, line: Int) {
        self.name = name
        self.line = line
    }
}
