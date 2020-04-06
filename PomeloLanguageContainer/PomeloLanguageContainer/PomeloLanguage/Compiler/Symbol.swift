//
//  Symbol.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/3/29.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class Signature {
    public enum SignatureType {
        case construct // 构造函数 xxx(_,...)
        case method    // 方法 xxx(_,...)
        case getter    // Getter xxx
        case setter    // Setter xxx=(_)
        case subscriptGetter    // xxx[_,...]
        case subscriptSetter    // xxx[_,...] = (_)
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
    public static var rulues: [Token.TokenType: SymbolBindRule] = [
        .unknown: ununseRule(),
        .num: prefixSymbolRule(nud: emitLiteral(unit:canAssign:)),
        .string: prefixSymbolRule(nud: emitLiteral(unit:canAssign:)),
        .id: SymbolBindRule(symbol: nil,
                            lbp: .none,
                            nud: nil, //TODO: id解析函数
                            led: nil,
                            methodSignature: idMethodSignature(unit:signature:))
    ]
    
    /// 指示符函数指针
    public typealias DenotationFn = (_ unit: CompilerUnit, _ canAssign: Bool) throws -> ()

    /// 签名函数指针
    public typealias MethodSignatureFn = (_ unit: CompilerUnit, _ signature: Signature) throws -> ()
    
    var symbol: String?
    var lbp: BindPower
    var nud: DenotationFn?
    var led: DenotationFn?
    var methodSignature: MethodSignatureFn?
    
    /// 注册如字面量、变量名等不关注左操作数的前缀符号
    public static func prefixSymbolRule(nud: @escaping DenotationFn) -> SymbolBindRule {
        return SymbolBindRule(symbol: nil,
                              lbp: .none,
                              nud: nud,
                              led: nil,
                              methodSignature: nil)
    }
    
    /// 注册前缀运算符，如!
    public static func prefixOperatorRule(id: String) -> SymbolBindRule {
        return SymbolBindRule(symbol: id,
                              lbp: .none,
                              nud: unaryOperator(unit:canAssign:),
                              led: nil,
                              methodSignature: unaryMethodSignature(unit:signature:))
    }
    
    /// 注册如数组[,函数(,实例与方法之间的.等关注左操作数的中缀符号
    public static func infixSymbolRule(lbp: BindPower, led: @escaping DenotationFn) -> SymbolBindRule {
        return SymbolBindRule(symbol: nil,
                              lbp: lbp,
                              nud: nil,
                              led: led,
                              methodSignature: nil)
    }
    
    /// 注册中缀运算符
    public static func infixOperatorRule(id: String, lbp: BindPower) -> SymbolBindRule {
        return SymbolBindRule(symbol: id,
                              lbp: lbp,
                              nud: nil,
                              led: infixOperator(unit:canAssign:),
                              methodSignature: infixMethodSignature(unit:signature:))
    }
    
    /// 注册既可作前缀有可做中缀的运算符，如-
    public static func mixOperatorRule(id: String) -> SymbolBindRule {
        return SymbolBindRule(symbol: id,
                              lbp: .term,
                              nud: unaryOperator(unit:canAssign:),
                              led: infixOperator(unit:canAssign:),
                              methodSignature: mixMethodSignature(unit:signature:))
    }
    
    /// 占位用
    public static func ununseRule() -> SymbolBindRule {
        return SymbolBindRule(symbol: nil,
                              lbp: .none,
                              nud: nil,
                              led: nil,
                              methodSignature: nil)
    }
}


/// 中缀运算符.led方法
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

/// 前缀运算符.nud方法，如-、!等
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

/// 单运算符方法签名函数
public func unaryMethodSignature(unit: CompilerUnit, signature: Signature) {
    signature.type = .getter
}

/// 中缀运算符方法签名函数
public func infixMethodSignature(unit: CompilerUnit, signature: Signature) throws {
    signature.type = .method
    signature.argNum = 1
    try! unit.curLexParser.consumeCurToken(expected: .leftParen, message: "中缀运算符后非\'(\'")
    try! unit.curLexParser.consumeCurToken(expected: .id, message: "中缀运算符后非变量名")

    //TODO: 需要处理字面量值,比如数字等
    guard let name = unit.curLexParser.preToken?.value as? String else {
        throw BuildError.general(message: "参数非变量名")
    }
    unit.declareVariable(name: name)
    try! unit.curLexParser.consumeCurToken(expected: .rightParen, message: "变量名后非\')\'")
}

/// 既是单运算符又是中缀运算符方法签名函数
public func mixMethodSignature(unit: CompilerUnit, signature: Signature) {
    signature.type = .getter
    guard unit.curLexParser.matchCurToken(expected: .leftParen) else {
        return
    }
    try! infixMethodSignature(unit: unit, signature: signature)
}


public func trySetterSignature(unit: CompilerUnit,signature: Signature) throws -> Bool {
    guard unit.curLexParser.matchCurToken(expected: .assign) else {
        return false
    }
    if signature.type == .subscriptGetter {
        signature.type = .subscriptSetter
    } else {
        signature.type = .setter
    }
    try! unit.curLexParser.consumeCurToken(expected: .leftParen, message: "=后非(")
    try! unit.curLexParser.consumeCurToken(expected: .id, message: "非id")
    guard let name = unit.curLexParser.preToken?.value as? String else {
        throw BuildError.general(message: "参数非变量名")
    }
    unit.declareVariable(name: name)
    try! unit.curLexParser.consumeCurToken(expected: .rightParen, message: "参数后非)")
    signature.argNum += 1
    return true
}


public func idMethodSignature(unit: CompilerUnit, signature: Signature) throws {
    signature.type = .getter
    if signature.name == "new" {
        guard unit.curLexParser.matchCurToken(expected: .leftParen) else {
            throw BuildError.general(message: "构造函数后必须跟(")
        }
        signature.type = .construct
    } else {
        if try! trySetterSignature(unit: unit, signature: signature) {
            return
        }
        guard unit.curLexParser.matchCurToken(expected: .leftParen) else {
            return
        }
        signature.type = .method
    }
    if unit.curLexParser.matchCurToken(expected: .rightParen) {
        return
    }
    try! emitProcessArgList(unit: unit, signature: signature)
    try! unit.curLexParser.consumeCurToken(expected: .rightParen, message: "方法参数后必须跟)")
}

/// 确保符号添加到符号表中
public func ensureSymbolExist(virtual: Virtual, symbolList: inout [String], name: String) -> Int {
    if let index = symbolList.firstIndex(of: name) {
        return index
    }
    symbolList.append(name)
    return symbolList.count - 1
}

public func getIndexFromSymbolList(list: [(name: String, value: AnyValue)], target: String) -> Int {
    if let index = list.firstIndex(where: { (name, _) -> Bool in name == target }) {
        return index
    }
    return -1
}
