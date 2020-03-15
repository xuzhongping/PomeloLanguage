//
//  Compiler.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public let maxLocalVarNum = 128
public let maxUpvalueNum = 128
public let maxIdLength = 128
public let maxMethodNameLength = maxIdLength
public let maxArgNum = 16
public let maxSignLenth = maxMethodNameLength + maxArgNum * 2 + 1
public let maxFieldNum = 128

public class Upvalue {
    var isEnclosingLocalVar: Bool
    var index: Int
    init() {
        isEnclosingLocalVar = false
        index = 0
    }
}

public class LocalVar {
    var name: String
    var scopeDepth: Int
    var isUpvalue: Bool
    init(name: String, scopeDepth: Int, isUpvalue: Bool) {
        self.name = name
        self.scopeDepth = scopeDepth
        self.isUpvalue = isUpvalue
    }
}

class Signature {
    enum SignatureType {
        case construct
        case method
        case getter
        case setter
        case subscriptGetter
        case subscriptSetter
    }
    var type: SignatureType
    var name: String
    var length: Int
    var argNum: Int
    init(type: SignatureType, name: String, argNum: Int) {
        self.type = type
        self.name = name
        self.argNum = argNum
        self.length = name.count
    }
}

class Loop {
    var condStartIndex: Int
    var bodyStartIndex: Int
    var scopeDepth: Int
    var exitIndex: Int
    var enclosingLoop: Loop?
    init() {
        condStartIndex = 0
        bodyStartIndex = 0
        scopeDepth = 0
        exitIndex = 0
    }
}

/// 用于记录类编译时的信息
class ClassBookKeep {
    var name: String
    var fields: [String: Value]
    var inStatic: Bool
    var instanceMethods: [Any]
    var staticMethods: [Any]
    var signature: Signature
    
    init(name: String, fields: [String: Value], instanceMethods: [Any], staticMethods: [Any], signature: Signature) {
        self.name = name
        self.fields = fields
        self.instanceMethods = instanceMethods
        self.staticMethods = staticMethods
        self.signature = signature
        self.inStatic = false
    }
}

class CompilerUnit {
    
    /// 当前编译函数
    var fn: FnObject?
    
    /// 当前作用域允许的局部变量数量上限
    var localVars: [LocalVar]
    
    /// 已分配的局部变量个数
    var localVarNum: Int
    
    /// 记录本层函数所引用的upvalue
    var upvalues: [Upvalue]
    
    /// 当前正在编译的代码所处作用域
    var scopeDepth: Int
    
    /// 当前使用的slot个数
    var stackSlotNum: Int
    
    /// 当前正在编译的循环层
    var curLoop: Loop?
    
    /// 当前正在编译的类的编译信息
    var enclosingClassBK: ClassBookKeep?
    
    /// 包含此编译单元的编译单元，直接外层
    var enclosingUnit: CompilerUnit?
    
    /// 当前词法解析器
    var curLexParser: LexParser
    
    init(lexParser: LexParser) {
        self.curLexParser = lexParser
        self.localVars = []
        self.localVarNum = 0
        self.upvalues = []
        self.scopeDepth = 0
        self.stackSlotNum = 0
    }
}

/// 编译Module(一个Pomelo脚本文件)
public func compileModule(virtual: Virtual, module: ModuleObject, code: String) -> FnObject {
    return FnObject(virtual: virtual, module: module, maxStackSize: 100)
}




