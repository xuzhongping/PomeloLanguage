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
    var index: Index
    init(index: Index, isEnclosingLocalVar: Bool) {
        self.index = index
        self.isEnclosingLocalVar = isEnclosingLocalVar
    }
}

public class LocalVar {
    public var name: String?
    public var scopeDepth: Int
    public var isUpvalue: Bool
    init(name: String?) {
        self.name = name
        self.scopeDepth = -1
        self.isUpvalue = false
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
public class ClassBookKeep {
    var name: String
    var fields: [(name: String, value: AnyValue)]
    var inStatic: Bool
    var instanceMethods: [Index]
    var staticMethods: [Index]
    var signature: Signature
    
    init(name: String, fields: (name: String, value: AnyValue), instanceMethods: [Index], staticMethods: [Index], signature: Signature) {
        self.name = name
        self.fields = [fields]
        self.instanceMethods = instanceMethods
        self.staticMethods = staticMethods
        self.signature = signature
        self.inStatic = false
    }
}



public class CompilerUnit: NSObject {
    
    /// 当前编译函数
    var fn: FnObject
    
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
    
    init(lexParser: LexParser, enclosingUnit: CompilerUnit?, isMethod: Bool) {
        self.curLexParser = lexParser
        self.enclosingUnit = enclosingUnit
        self.enclosingClassBK = nil
        self.localVarNum = 1
        self.stackSlotNum = 1
        self.localVars = []
        self.upvalues = []
        if let _ = enclosingUnit {
            if isMethod {
                let thisLocalVar = LocalVar(name: "this")
                self.localVars.append(thisLocalVar)
            } else {
                let thisLocalVar = LocalVar(name: nil)
                self.localVars.append(thisLocalVar)
            }
            self.localVars.first?.scopeDepth = -1
            self.scopeDepth = 0
        } else {
            /// 没有外层编译单元，说明是模块作用域
            /// 模块作用域为-1
            self.scopeDepth = -1
            self.localVarNum = 0
        }
        self.fn = FnObject(virtual: curLexParser.virtual, module: curLexParser.curModule, maxStackSize: self.localVarNum)
        super.init()
        lexParser.curCompileUnit = self
    }
}


// MARK: 指令写入基础
extension CompilerUnit {
    @discardableResult
    public func writeByte(byte: Byte) -> Int{
        #if DEBUG
        //TODO: 写入行号
        #endif
       
        fn.byteStream.append(byte)
        return fn.byteStream.count - 1
    }
   
   /// 写入操作码
   public func writeOpCode(code: OP_CODE) {
       writeByte(byte: code.rawValue)
       stackSlotNum += OP_CODE_SLOTS_USED[Int(code.rawValue)]
       fn.maxStackSize = max(fn.maxStackSize, stackSlotNum)
   }
   
   /// 写入1字节的操作数
   public func writeByteOperand(operand: Int) {
       writeByte(byte: Byte(operand))
   }
   
   /// 写入2字节操作数
   public func writeShortOperand(operand: Int) {
       writeByte(byte: Byte((operand >> 8) & 0xff))
       writeByte(byte: Byte(operand & 0xff))
   }
   
   /// 写入操作数为1字节的指令
   public func writeOpCodeByteOperand(code: OP_CODE, operand: Int) {
       writeOpCode(code: code)
       writeByteOperand(operand: operand)
   }
   
   /// 写入操作数为2字节的指令
   public func writeOpCodeShortOperand(code: OP_CODE, operand: Int) {
       writeOpCode(code: code)
       writeShortOperand(operand: operand)
   }
       
}

// MARK: 变量操作相关
extension CompilerUnit {
   
    public func compileProgram() {
        
    }
    
    /// 添加局部变量
    public func addLocalVar(name: String) -> Int {
        let localVar = LocalVar(name: name)
        localVar.scopeDepth = scopeDepth
        localVar.isUpvalue = false
        localVars.append(localVar)
        return localVars.count - 1
    }
    
    /// 声明局部变量
    public func declareLocalVar(name: String) throws -> Int {
        guard localVars.count >= maxArgNum else {
           throw BuildError.general(message: "已分配局部变量数量超过最大值")
        }
       
        for localVar in localVars.reversed() {
           guard localVar.scopeDepth >= scopeDepth else { break }
           guard localVar.name != name else { throw BuildError.general(message: "重新定义变量\(name)") }
        }
        return addLocalVar(name: name)
    }
   
    @discardableResult
    public func declareVariable(name: String) -> Int {
        if scopeDepth == -1 {
            let index = try! curLexParser.curModule.defineVar(virtual: curLexParser.virtual,
                                                             name: name,
                                                             value: AnyValue(value: nil))
            return index
        }
        return try! declareLocalVar(name: name)
    }
    
    /// 添加常量并返回索引
    public func addConstant(constant: AnyValue) -> Int {
        fn.constantsList.append(constant)
        return fn.constantsList.count - 1
    }
    
    public func getEnclosingClassBKUnit() -> CompilerUnit? {
        var unit: CompilerUnit? = self
        while unit != nil {
            if unit?.enclosingClassBK != nil {
                return unit
            }
            unit = unit?.enclosingUnit
        }
        return nil
    }
    
    public func getEnclosingClassBK() -> ClassBookKeep? {
        if let unit = getEnclosingClassBKUnit() {
            return unit.enclosingClassBK
        }
        return nil
    }
    
    /// 查找局部变量
    public func findLocalVar(name: String) -> Int {
        return localVars.firstIndex { (localVar) -> Bool in localVar.name == name } ?? -1
    }
    
    /// 添加upvalue
    public func addUpvalue(isEnclosingLocalVar: Bool, index: Index) -> Int {
        let index = upvalues.firstIndex { (upvalue) -> Bool in
            upvalue.index == index && upvalue.isEnclosingLocalVar == isEnclosingLocalVar
        } ?? -1
        if index >= 0 {
            return index
        }
        upvalues.append(Upvalue(index: index, isEnclosingLocalVar: isEnclosingLocalVar))
        return upvalues.count - 1
    }
    
    /// 查找名为name的upvalue添加到upvalues中，返回其索引
    public func findUpvalue(name: String) -> Int {
        guard let enclosingUnit = enclosingUnit else { return IndexNotFound }
        if !name.contains(" ") && enclosingUnit.enclosingClassBK != nil {
            return IndexNotFound
        }
        let localIndex = enclosingUnit.findLocalVar(name: name)
        if localIndex >= 0 {
            return addUpvalue(isEnclosingLocalVar: true, index: localIndex)
        }
        let upvalueIndex = enclosingUnit.findUpvalue(name: name)
        if upvalueIndex >= 0 {
            return addUpvalue(isEnclosingLocalVar: false, index: upvalueIndex)
        }
        return IndexNotFound
    }
    
    /// 从局部变量和upvalue中查找符号name
    public func findVarFromLocalOrUpvalue(name: String) -> Variable? {
        var index = findLocalVar(name: name)
        if index != IndexNotFound {
            return Variable(type: .local, index: index)
        }
        index = findUpvalue(name: name)
        if index != IndexNotFound {
            return Variable(type: .upvalue, index: index)
        }
        return nil
    }
}

// MARK: 生成指令相关
extension CompilerUnit {
    /// 生成加载常量的指令
    public func emitLoadConstant(constant: AnyValue) {
        let index = addConstant(constant: constant)
        writeOpCodeShortOperand(code: .LOAD_CONSTANT, operand: index)
    }
    
    /// 生成数字和字符串.nud()字面量指令
    public func emitLiteral(canAssign: Bool) {
        //TODO: value类型修改
        emitLoadConstant(constant: AnyValue(value: curLexParser.preToken?.value))
    }
    
    /// 通过签名生成方法调用指令
    public func emitCallBySignature(signature: Signature, opCode: OP_CODE) {
        let name = signature.toString()
        emitCall(argsNum: signature.argNum, name: name)
        if opCode == .SUPER0 {
            writeShortOperand(operand: addConstant(constant: AnyValue(value: nil)))
        }
    }

    /// 通过方法名生成调用指令
    public func emitCall(argsNum: Int, name: String) {
        let index = ensureSymbolExist(virtual: curLexParser.virtual,
                                      symbolList: &curLexParser.virtual.allMethodNames,
                                      name: name)
        if let opCode = OP_CODE(rawValue: OP_CODE.CALL0.rawValue + Byte(argsNum)) {
            writeOpCodeShortOperand(code:opCode , operand: index)
        }
    }
    
    /// 为实参列表各个参数生成加载实参的指令
    public func processArgList(signature: Signature) throws {
        guard let token = curLexParser.curToken else {
            throw BuildError.general(message: "Token为空")
        }
        guard token.type != .rightParen, token.type != .rightBracket else {
            throw BuildError.general(message: "参数列表为空")
        }
        repeat {
            if signature.argNum > maxArgNum {
                throw BuildError.general(message: "参数个数超过最大")
            }
            try! expression(unit: self, rbp: .lowest)
        } while curLexParser.matchCurToken(expected: .comma)
    }
    
    public func processParaList(signature: Signature) throws {
        guard let token = curLexParser.curToken else {
            throw BuildError.general(message: "Token为空")
        }
        guard token.type != .rightParen, token.type != .rightBracket else {
            throw BuildError.general(message: "参数列表为空")
        }
        
        repeat {
            if signature.argNum > maxArgNum {
                throw BuildError.general(message: "参数个数超过最大")
            }
            try! curLexParser.consumeCurToken(expected: .id, message: "中缀运算符后非变量名")
            //TODO: 需要处理字面量值,比如数字等
            guard let name = curLexParser.preToken?.value as? String else {
                throw BuildError.general(message: "参数非变量名")
            }
            declareVariable(name: name)
        } while curLexParser.matchCurToken(expected: .comma)
    }
    
    /// 生成加载变量到栈的指令
    public func emitLoadVariable(variable: Variable) {
        switch variable.type {
        case .local:
            writeOpCodeByteOperand(code: OP_CODE.LOAD_LOCAL_VAR, operand: variable.index)
        case .upvalue:
            writeOpCodeByteOperand(code: OP_CODE.LOAD_UPVALUE, operand: variable.index)
        case .module:
            writeOpCodeByteOperand(code: OP_CODE.LOAD_MODULE_VAR, operand: variable.index)
        default:
            break
        }
    }
    
    /// 生成从栈顶弹出数据到变量中存储的指令
    public func emitStoreVariable(variable: Variable) {
        switch variable.type {
        case .local:
            writeOpCodeByteOperand(code: OP_CODE.STORE_LOCAL_VAR, operand: variable.index)
        case .upvalue:
            writeOpCodeByteOperand(code: OP_CODE.STORE_UPVALUE, operand: variable.index)
        case .module:
            writeOpCodeByteOperand(code: OP_CODE.STORE_MODULE_VAR, operand: variable.index)
        default:
            break
        }
    }
    
    /// 生成加载或存储变量的指令
    public func emitLoadOrStoreVariable(assign: Bool, variable: Variable) {
        if assign && curLexParser.matchCurToken(expected: .assign) {
            try! expression(unit: self, rbp: .lowest)
            emitStoreVariable(variable: variable)
        } else {
            emitLoadVariable(variable: variable)
        }
    }
}

/// 用于内部变量查找
public class Variable: NSObject {
    public enum ScopeType {
        case invalid
        case local
        case upvalue
        case module
    }
    var type: ScopeType
    var index: Int
    init(type: ScopeType, index: Int) {
        self.type = type
        self.index = index
    }
}

/// 编译Module(一个Pomelo脚本文件)
public func compileModule(virtual: Virtual, module: ModuleObject, code: String) throws -> FnObject {
    var lexParser: LexParser
    if let name = module.name {
        lexParser = LexParser(virtual: virtual,
                              moduleName: name,
                              module: module,
                              code: code)
    } else {
        lexParser = LexParser(virtual: virtual,
                              moduleName: "core.script.inc",
                              module: module,
                              code: code)
    }
    
    let moduleUnit = CompilerUnit(lexParser: lexParser, enclosingUnit: nil, isMethod: false)
    
    
    let moduleVarNumBefor = module.vars.count
    
    try! lexParser.nextToken()
    
    while !lexParser.matchCurToken(expected: .eof) {
        moduleUnit.compileProgram()
    }
    
    return FnObject(virtual: virtual, module: module, maxStackSize: 100)
}


/// 语法分析核心
public func expression(unit: CompilerUnit, rbp: SymbolBindRule.BindPower) throws {
    guard let curToken = unit.curLexParser.curToken else {
        return
    }
    guard let nud = SymbolBindRule.rulues[curToken.type]?.nud else {
        throw BuildError.unknown
    }
    try! unit.curLexParser.nextToken()

    let canAssign = rbp.rawValue < SymbolBindRule.BindPower.assign.rawValue
    nud(unit,canAssign)

    while true {
        guard let token = unit.curLexParser.curToken else {
            break
        }
        guard let lbp = SymbolBindRule.rulues[token.type]?.lbp else {
            break
        }
        guard rbp.rawValue < lbp.rawValue else {
            break
        }
        guard let led = SymbolBindRule.rulues[token.type]?.led else {
            break
        }
        try! unit.curLexParser.nextToken()
        led(unit, canAssign)
    }
}

