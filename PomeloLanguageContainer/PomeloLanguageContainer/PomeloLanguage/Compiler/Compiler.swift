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
    init() {
        isEnclosingLocalVar = false
        index = 0
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

public class Signature {
    public enum SignatureType {
        case construct // 构造函数
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
    public init(type: SignatureType, name: String, argNum: Int) {
        self.type = type
        self.name = name
        self.argNum = argNum
        self.length = name.count
    }
    
    public func toString() -> String {
        var signatureStr = name
        switch type {
            case .getter:
                break
            case .setter:
                signatureStr.append(contentsOf: "=(_)")
            case .construct, .method:
                signatureStr.append("(")
                for i in 0..<argNum {
                    signatureStr.append("_")
                    if i < argNum - 1 { signatureStr.append(",") }
                }
                signatureStr.append(")")
            case .subscriptGetter:
                signatureStr.append("[")
                for i in 0..<argNum {
                    signatureStr.append("_")
                    if i < argNum - 1 { signatureStr.append(",") }
                }
                signatureStr.append("]")
            case .subscriptSetter:
                signatureStr.append("[")
                for i in 0..<argNum {
                    signatureStr.append("_")
                    if i < argNum - 1 { signatureStr.append(",") }
                }
                signatureStr.append(contentsOf: "]=(_)")
        }
        return signatureStr
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
    var fields: [(name: String, value: Value)]
    var inStatic: Bool
    var instanceMethods: [Index]
    var staticMethods: [Index]
    var signature: Signature
    
    init(name: String, fields: (name: String, value: Value), instanceMethods: [Index], staticMethods: [Index], signature: Signature) {
        self.name = name
        self.fields = [fields]
        self.instanceMethods = instanceMethods
        self.staticMethods = staticMethods
        self.signature = signature
        self.inStatic = false
    }
}



/// 符号绑定规则
public struct SymbolBindRule {
    public enum BindPower: Int {
        case none
        case lowest
        case assign
        case condition
        case logic_or
        case logic_and
        case equal
        case is_
        case cmp
        case bit_or
        case bit_and
        case bit_shift
        case range
        case term
        case factor
        case unary
        case call
        case highest
    }
    public static var rulues: [Token.TokenType: SymbolBindRule] = [:]
    
    /// 指示符函数指针
    public typealias DenotationFn = (_ unit: CompilerUnit, _ canAssign: Bool) -> ()

    /// 签名函数指针
    public typealias MethodSignatureFn = (_ unit: CompilerUnit, _ signature: Signature) -> ()
    
    var symbol: String?
    var lbp: BindPower
    var nud: DenotationFn?
    var led: DenotationFn?
    var methodSignature: MethodSignatureFn?
    
    public static func prefixSymbol(nud: @escaping DenotationFn) -> SymbolBindRule {
        return SymbolBindRule(symbol: nil,
                              lbp: .none,
                              nud: nud,
                              led: nil,
                              methodSignature: nil)
    }
    
    public static func prefixOperator(id: String) -> SymbolBindRule {
        return SymbolBindRule(symbol: id,
                              lbp: .none,
                              nud: unaryOperator(unit:canAssign:),
                              led: nil,
                              methodSignature: unaryMethodSignature(unit:signature:))
    }
    
    public static func infixSymbol(lbp: BindPower, led: @escaping DenotationFn) -> SymbolBindRule {
        return SymbolBindRule(symbol: nil,
                              lbp: lbp,
                              nud: nil,
                              led: led,
                              methodSignature: nil)
    }
    
    public static func infixOperator(id: String, lbp: BindPower) -> SymbolBindRule {
        return SymbolBindRule(symbol: id,
                              lbp: lbp,
                              nud: nil,
                              led: infixOperator(unit:canAssign:),
                              methodSignature: infixMethodSignature(unit:signature:) as? SymbolBindRule.MethodSignatureFn)
    }
    
    public static func mixOperator(id: String) -> SymbolBindRule {
        return SymbolBindRule(symbol: id,
                              lbp: .term,
                              nud: unaryOperator(unit:canAssign:),
                              led: infixOperator(unit:canAssign:),
                              methodSignature: mixMethodSignature(unit:signature:))
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
            /// 模块作用域为-1
            self.scopeDepth = -1
            self.localVarNum = 0
        }
        self.fn = FnObject(virtual: curLexParser.virtual, module: curLexParser.curModule, maxStackSize: uint64(self.localVarNum))
        super.init()
        lexParser.curCompileUnit = self
    }
    @discardableResult
    public func writeByte(byte: Byte) -> Int{
        #if DEBUG
        //TODO: 写入行号
        #endif
        fn.instrStream.append(byte)
        return fn.instrStream.count - 1
    }
    
    /// 写入操作码
    public func writeOpCode(code: OP_CODE) {
        writeByte(byte: code.rawValue)
        stackSlotNum += OP_CODE_SLOTS_USED[Int(code.rawValue)]
    }
    
    /// 写入1字节的操作数
    public func writeByteOperand(operand: Int) -> Int {
        return writeByte(byte: Byte(operand))
    }
    
    /// 写入2字节操作数
    public func writeShortOperand(operand: Int) {
        writeByte(byte: Byte((operand >> 8) & 0xff))
        writeByte(byte: Byte(operand & 0xff))
    }
    
    /// 写入操作数为1字节的指令
    public func writeOpCodeByteOperand(code: OP_CODE, operand: Int) -> Int {
        writeOpCode(code: code)
        return writeByteOperand(operand: operand)
    }
    
    /// 写入操作数为2字节的指令
    public func writeOpCodeShortOperand(code: OP_CODE, operand: Int) {
        writeOpCode(code: code)
        writeShortOperand(operand: operand)
    }
    
    public func compileProgram() {
        
    }
    
    /// 添加常量并返回索引
    public func addConstant(constant: Value) -> Int {
        fn.constantsList.append(constant)
        return fn.constantsList.count - 1
    }
    
    /// 生成加载常量的指令
    public func emitLoadConstant(constant: Value) {
        let index = addConstant(constant: constant)
        writeOpCodeShortOperand(code: .LOAD_CONSTANT, operand: index)
    }
    
    /// 数字和字符串.nud()编译字面量
    public func literal(canAssign: Bool) {
        if let value = curLexParser.preToken?.value {
            //TODO: value类型修改
            emitLoadConstant(constant: value as! Value)
        }
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
    public func declareVariable(name: String) throws -> Int {
        if scopeDepth == -1 {
            let index = try defineModuleVar(virtual: curLexParser.virtual,
                                            module: curLexParser.curModule,
                                            name: name,
                                            value: Value(type: .null))
            return index
        }
        return try declareLocalVar(name: name)
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
            try declareVariable(name: name)
        } while curLexParser.matchCurToken(expected: .comma)
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
    
    let moduleCU = CompilerUnit(lexParser: lexParser, enclosingUnit: nil, isMethod: false)
    let moduleVarNumBefor = module.vars.count
    
    let token = try lexParser.nextToken()
    
    while true {
        moduleCU.compileProgram()
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

public func emitCallBySignature(unit: CompilerUnit, signature: Signature, opCode: OP_CODE) {
    let symbol = signature.toString()
    let index = ensureSymbolExist(
            virtual: unit.curLexParser.virtual,
            table: &unit.curLexParser.virtual.allMethodNames,
            symbol: symbol)
    unit.writeOpCodeShortOperand(code: opCode, operand: index)
    if opCode == .SUPER0 {
        unit.writeShortOperand(operand: unit.addConstant(constant: Value(type: .null)))
    }
}

public func emitCall(unit: CompilerUnit, argsNum: Int, name: String) {
    let index = ensureSymbolExist(virtual: unit.curLexParser.virtual, table: &unit.curLexParser.virtual.allMethodNames, symbol: name)
    if let opCode = OP_CODE(rawValue: OP_CODE.CALL0.rawValue + Byte(argsNum)) {
        unit.writeOpCodeShortOperand(code:opCode , operand: index)
    }
}

public func infixOperator(unit: CompilerUnit, canAssign: Bool) {
    guard let curToken = unit.curLexParser.curToken else {
        return
    }
    guard let rule = SymbolBindRule.rulues[curToken.type] else {
        return
    }
    let rbp = rule.lbp
    try! expression(unit: unit, rbp: rbp)
    
    let signature = Signature(type: .method, name: rule.symbol ?? "", argNum: 1)
    emitCallBySignature(unit: unit, signature: signature, opCode: OP_CODE.CALL0)
}

public func unaryOperator(unit: CompilerUnit, canAssign: Bool) {
    guard let curToken = unit.curLexParser.curToken else {
        return
    }
    guard let rule = SymbolBindRule.rulues[curToken.type] else {
        return
    }
    try! expression(unit: unit, rbp: SymbolBindRule.BindPower.unary)
    emitCall(unit: unit, argsNum: 0, name: rule.symbol ?? "")
}

/// 单运算符方法签名
public func unaryMethodSignature(unit: CompilerUnit, signature: Signature) {
    signature.type = .getter
}

/// 中缀运算符方法签名
public func infixMethodSignature(unit: CompilerUnit, signature: Signature) throws {
    signature.type = .method
    signature.argNum = 1
    try! unit.curLexParser.consumeCurToken(expected: .leftParen, message: "中缀运算符后非\'(\'")
    try! unit.curLexParser.consumeCurToken(expected: .id, message: "中缀运算符后非变量名")

    //TODO: 需要处理字面量值,比如数字等
    guard let name = unit.curLexParser.preToken?.value as? String else {
        throw BuildError.general(message: "参数非变量名")
    }
    try! unit.declareVariable(name: name)
    try! unit.curLexParser.consumeCurToken(expected: .rightParen, message: "变量名后非\')\'")
}

/// 既是单运算符又是中缀运算符方法签名
public func mixMethodSignature(unit: CompilerUnit, signature: Signature) {
    signature.type = .getter
    guard try! unit.curLexParser.matchCurToken(expected: .leftParen) else {
        return
    }
    try! infixMethodSignature(unit: unit, signature: signature)
}

