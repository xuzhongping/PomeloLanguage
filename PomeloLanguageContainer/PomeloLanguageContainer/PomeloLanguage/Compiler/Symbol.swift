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
    /// 绑定能力
    public enum BindPower: Int {
        case none
        case lowest // 最低
        case assign // =
        case condition  // ?:
        case logic_or   // ||
        case logic_and  // &&
        case equal  // ==、!=
        case is_    // is
        case cmp    // <、>、<=、>=
        case bit_or // |
        case bit_and    // &
        case bit_shift  // <<、>>
        case range  // ..
        case term   // +、-
        case factor // *、/、%
        case unary  // -、!、~
        case call   // .、()、[]
        case highest    // 最高
    }
    
    /// 指示符函数指针
    public typealias DenotationFn = (_ unit: CompilerUnit, _ assign: Bool) -> ()

    /// 签名函数指针
    public typealias MethodSignatureFn = (_ unit: CompilerUnit, _ signature: Signature) -> ()
    
    var symbol: String?
    /// 左邦定权值
    var lbp: BindPower
    /// 字面量、变量、前缀运算符等不关注左操作数的token调用的方法
    var nud: DenotationFn?
    /// 中缀运算符等关注左操作数的token调用的方法
    var led: DenotationFn?
    /// 方法签名
    var methodSignature: MethodSignatureFn?
    
    /// 所有类型的token绑定规则
    public static var rulues: [Token.TokenType: SymbolBindRule] {
        [
            .unknown: ununseRule(),
            .num: prefixSymbolRule(nud: emitLiteral(unit:assign:)),
            .string: prefixSymbolRule(nud: emitLiteral(unit:assign:)),
            .id: SymbolBindRule(symbol: nil,
                                lbp: .none,
                                nud: emitId(unit:assign:), //TODO: id解析函数
                                led: nil,
                                methodSignature: idMethodSignature(unit:signature:)),
            .interpolation: prefixSymbolRule(nud: emitStringInterpolation(unit:assgin:)),
            .var_: ununseRule(),
            .func_: ununseRule(),
            .if_: ununseRule(),
            .else_: ununseRule(),
            .true_: prefixSymbolRule(nud: emitBoolean(unit:assign:)),
            .false_: prefixSymbolRule(nud: emitBoolean(unit:assign:)),
            .while_: ununseRule(),
            .for_: ununseRule(),
            .break_: ununseRule(),
            .continue_: ununseRule(),
            .return_: ununseRule(),
            .null: prefixSymbolRule(nud: emitNull(unit:assign:)),
            .class_: ununseRule(),
            .this: prefixSymbolRule(nud: emitThis(unit:assign:)),
            .static_: ununseRule(),
            .is_: infixOperatorRule(id: "is", lbp: .is_),
            .super_: prefixSymbolRule(nud: emitSuper(unit:assign:)),
            .import_: ununseRule(),
            .comma: ununseRule(),
            .colon: ununseRule(),
            .leftParen: prefixSymbolRule(nud: emitParentheses(unit:assign:)),
            .rightParen: ununseRule(),
            .leftBracket: SymbolBindRule(symbol: nil,
                                         lbp: .call,
                                         nud: emitListLiteral(unit:assgin:),
                                         led: emitSubscript(unit:assign:),
                                         methodSignature: subscriptMethodSignature(unit:signature:)),
            .rightBracket: ununseRule(),
            .leftBrace: prefixSymbolRule(nud: emitMapLiteral(unit:assign:)),
            .rightBrace: ununseRule(),
            .dot: infixSymbolRule(lbp: .call, led: emitCallEntry(unit:assign:)),
            .dotDouble: infixOperatorRule(id: "..", lbp: .range),
            .add: infixOperatorRule(id: "+", lbp: .term),
            .sub: mixOperatorRule(id: "-"),
            .mul: infixOperatorRule(id: "*", lbp: .factor),
            .div: infixOperatorRule(id: "/", lbp: .factor),
            .mod: infixOperatorRule(id: "%", lbp: .factor),
            .assign: ununseRule(),
            .bitAnd: infixOperatorRule(id: "&", lbp: .bit_and),
            .bitOr: infixOperatorRule(id: "|", lbp: .bit_or),
            .bitNot: prefixOperatorRule(id: "~"),
            .bitShiftLeft: infixOperatorRule(id: "<<", lbp: .bit_shift),
            .bitShiftRight: infixOperatorRule(id: ">>", lbp: .bit_shift),
            .logicAnd: infixSymbolRule(lbp: .logic_and, led: emitLogicAnd(unit:assign:)),
            .logicOr: infixSymbolRule(lbp: .logic_or, led: emitLogicOr(unit:assign:)),
            .logicNot: prefixOperatorRule(id: "!"),
            .equal: infixOperatorRule(id: "==", lbp: .equal),
            .notEqual: infixOperatorRule(id: "!=", lbp: .equal),
            .greate: infixOperatorRule(id: ">", lbp: .cmp),
            .greateEqual: infixOperatorRule(id: ">=", lbp: .cmp),
            .less: infixOperatorRule(id: "<", lbp: .cmp),
            .lessEqual: infixOperatorRule(id: "<=", lbp: .cmp),
            
            .question: infixSymbolRule(lbp: .assign, led: emitCondition(unit:assign:)),
            .eof: ununseRule()
        ]
    }
    
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
                              nud: emitUnaryOperator(unit:assign:),
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
                              led: emitInfixOperator(unit:assign:),
                              methodSignature: infixMethodSignature(unit:signature:))
    }
    
    /// 注册既可作前缀有可做中缀的运算符，如-
    public static func mixOperatorRule(id: String) -> SymbolBindRule {
        return SymbolBindRule(symbol: id,
                              lbp: .term,
                              nud: emitUnaryOperator(unit:assign:),
                              led: emitInfixOperator(unit:assign:),
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




/// 单运算符方法签名函数
public func unaryMethodSignature(unit: CompilerUnit, signature: Signature) {
    signature.type = .getter
}

/// 中缀运算符方法签名函数
public func infixMethodSignature(unit: CompilerUnit, signature: Signature) {
    signature.type = .method
    signature.argNum = 1
    
    unit.curLexParser.consumeCurToken(expected: .leftParen, message: "中缀运算符后非\'(\'")
    unit.curLexParser.consumeCurToken(expected: .id, message: "中缀运算符后非变量名")

    //TODO: 需要处理字面量值,比如数字等
    guard let name = unit.curLexParser.preToken?.value as? String else {
        fatalError("参数非变量名")
    }

    unit.declareVariable(name: name)
    unit.curLexParser.consumeCurToken(expected: .rightParen, message: "变量名后非\')\'")
}

/// 既是单运算符又是中缀运算符方法签名函数
public func mixMethodSignature(unit: CompilerUnit, signature: Signature) {
    signature.type = .getter
    guard unit.curLexParser.matchCurToken(expected: .leftParen) else {
        return
    }
    infixMethodSignature(unit: unit, signature: signature)
}

@discardableResult
public func trySetterSignature(unit: CompilerUnit,signature: Signature) -> Bool {
    guard unit.curLexParser.matchCurToken(expected: .assign) else {
        return false
    }
    if signature.type == .subscriptGetter {
        signature.type = .subscriptSetter
    } else {
        signature.type = .setter
    }
    unit.curLexParser.consumeCurToken(expected: .leftParen, message: "=后非(")
    unit.curLexParser.consumeCurToken(expected: .id, message: "非id")
    guard let name = unit.curLexParser.preToken?.value as? String else {
        fatalError("参数非变量名")
    }
    unit.declareVariable(name: name)
    unit.curLexParser.consumeCurToken(expected: .rightParen, message: "参数后非)")
    signature.argNum += 1
    return true
}


public func idMethodSignature(unit: CompilerUnit, signature: Signature) {
    signature.type = .getter
    if signature.name == "new" {
        if unit.curLexParser.matchCurToken(expected: .assign) {
            fatalError("constructor shouldn`t be setter!")
        }
        
        guard unit.curLexParser.matchCurToken(expected: .leftParen) else {
            fatalError("构造函数后必须跟(")
        }
        signature.type = .construct
        
    } else {
        if trySetterSignature(unit: unit, signature: signature) {
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
    
    emitProcessArgList(unit: unit, signature: signature)
    unit.curLexParser.consumeCurToken(expected: .rightParen, message: "方法参数后必须跟)")
}

public func subscriptMethodSignature(unit: CompilerUnit, signature: Signature) {
    signature.type = .subscriptGetter
    signature.length = 0
    emitProcessParaList(unit: unit, signature: signature)
    unit.curLexParser.consumeCurToken(expected: .rightBracket, message: "expect ']' after index list!")
    trySetterSignature(unit: unit, signature: signature)
} 

/// 确保符号添加到符号表中
public func ensureSymbolExist(virtual: Virtual, symbolList: inout [String], name: String) -> Int {
    if let index = symbolList.firstIndex(of: name) {
        return index
    }
    symbolList.append(name)
    return symbolList.lastIndex
}

public func getIndexFromSymbolList(list: [(name: String, value: AnyValue)], target: String) -> Int {
    if let index = list.firstIndex(where: { (name, _) -> Bool in name == target }) {
        return index
    }
    return -1
}

//public func addSymbol()
