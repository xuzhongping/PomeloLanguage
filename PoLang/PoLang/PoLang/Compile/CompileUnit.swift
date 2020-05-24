//
//  CompileUnit.swift
//  PoLang
//
//  Created by xuzhongping on 2020/5/24.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class LocalVar: NSObject {
    public var name: String
    public var scopeDepth: ScopeDepth
    public var isUpvalue: Bool
    
    public init(name: String) {
        self.name = name
        self.scopeDepth = ScopeDepth.module
        self.isUpvalue = false
    }
    public static var placeholder: LocalVar {
        return LocalVar(name: "pomepo.placehodler")
    }
}

public class Upvalue {
    var isEnclosingLocalVar: Bool
    var index: Index
    init(index: Index, isEnclosingLocalVar: Bool) {
        self.index = index
        self.isEnclosingLocalVar = isEnclosingLocalVar
    }
}

public class Loop: NSObject {
    var condStartIndex: Index
    var bodyStartIndex: Index
    var scopeDepth: ScopeDepth
    var exitIndex: Index
    var enclosingLoop: Loop?
    override init() {
        condStartIndex = 0
        bodyStartIndex = 0
        scopeDepth = 0
        exitIndex = 0
    }
}

public class ClassBookKeep {
    var name: String
    var fields: [String]
    var inStatic: Bool
    var instanceMethods: [Index]
    var staticMethods: [Index]
    var signature: Signature?
        
    init(name: String) {
        self.name = name
        self.fields = []
        self.instanceMethods = []
        self.staticMethods = []
        self.inStatic = false
    }
}

public class Variable: NSObject {
    public enum ScopeType {
        case local
        case upvalue
        case module
    }
    var type: ScopeType
    /// 此索引指向模块变量或局部变量或upvalue
    var index: Index
    init(type: ScopeType, index: Index) {
        self.type = type
        self.index = index
    }
}

public class CompileUnit: NSObject {
    /// 当前编译函数
    var fn: FnInfo
    
    /// 当前作用域的局部变量
    var localVars: [LocalVar]
    
    /// 记录本层函数所引用的upvalue
    var upvalues: [Upvalue]
    
    /// 当前正在编译的代码所处作用域
    var scopeDepth: ScopeDepth
    
    /// 当前使用的slot个数
    var stackSlotNum: Int
    
    /// 当前正在编译的循环层
    var curLoop: Loop?
    
    /// 当前正在编译的类的编译信息
    var enclosingClassBK: ClassBookKeep?
    
    /// 包含此编译单元的编译单元，直接外层
    var enclosingUnit: CompileUnit?
    
    var context: RuntimeContext
    
    init(context: RuntimeContext, enclosingUnit: CompileUnit?, isMethod: Bool) {
        self.localVars = []
        self.upvalues = []
        self.stackSlotNum = 1
        self.enclosingUnit = enclosingUnit
        self.context = context
        
        // 有外层单元，这里是局部作用域
        if let _ = enclosingUnit {
            if isMethod {
                let thisLocalVar = LocalVar(name: "this")
                self.localVars.append(thisLocalVar)
            } else {
                let thisLocalVar = LocalVar.placeholder
                self.localVars.append(thisLocalVar)
            }
            scopeDepth = ScopeDepth.normal
        } else {
            /// 没有外层编译单元，说明是模块作用域
            /// 模块作用域为-1
            scopeDepth = ScopeDepth.module
        }
        
        self.fn = FnInfo(stackCapacity: localVars.count)
        super.init()
    }
    
}

extension CompileUnit {
    @discardableResult
    private func writeByte(byte: Byte) -> Index {
        fn.bytes.append(byte)
        return fn.bytes.lastIndex
     }

    /// 写入操作码
    @discardableResult
    private func writeOpCode(code: OP_CODE) -> Index {
        writeByte(byte: code.rawValue)
        stackSlotNum += OP_CODE_SLOTS_USED[Int(code.rawValue)]
        fn.maxStackSize = max(fn.maxStackSize, stackSlotNum)
        return fn.bytes.lastIndex
    }

    /// 写入1字节的操作数
    @discardableResult
    public func writeByteOperand(operand: Int) -> Index {
        return writeByte(byte: Byte(operand))
    }

    /// 写入2字节操作数
    @discardableResult
    public func writeShortOperand(operand: Int) -> Index {
        writeByte(byte: Byte((operand >> 8) & 0xff))
        return writeByte(byte: Byte(operand & 0xff))
    }

    /// 写入操作数为1字节的指令
    @discardableResult
    public func writeByteCode(code: OP_CODE, operand: Int) -> Index {
        writeOpCode(code: code)
        writeByteOperand(operand: operand)
        PLDebugPrint("write2: \(code) \(operand)")
        return fn.bytes.lastIndex
    }

    /// 写入操作数为2字节的指令
    @discardableResult
    public func writeShortByteCode(code: OP_CODE, operand: Int) -> Index {
        writeOpCode(code: code)
        PLDebugPrint("write1: \(code) \(operand)")
        return writeShortOperand(operand: operand)
    }

}
