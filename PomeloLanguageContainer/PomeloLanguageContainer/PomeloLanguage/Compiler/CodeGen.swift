//
//  CodeGen.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/3/30.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

//MARK: Base
@discardableResult
public func writeByte(unit: CompilerUnit, byte: Byte) -> Int{
    #if DEBUG
    //TODO: 写入行号
    #endif
    unit.fn.byteStream.append(byte)
    
    return unit.fn.byteStream.count - 1
 }

/// 写入操作码
public func writeOpCode(unit: CompilerUnit, code: OP_CODE) {
    writeByte(unit: unit, byte: code.rawValue)
    unit.stackSlotNum += OP_CODE_SLOTS_USED[Int(code.rawValue)]
    unit.fn.maxStackSize = max(unit.fn.maxStackSize, unit.stackSlotNum)
}

/// 写入1字节的操作数
public func writeByteOperand(unit: CompilerUnit, operand: Int) {
    writeByte(unit: unit, byte: Byte(operand))
}

/// 写入2字节操作数
public func writeShortOperand(unit: CompilerUnit, operand: Int) {
    writeByte(unit: unit, byte: Byte((operand >> 8) & 0xff))
    writeByte(unit: unit, byte: Byte(operand & 0xff))
}

/// 写入操作数为1字节的指令
public func writeByteCode(unit: CompilerUnit, code: OP_CODE, operand: Int) {
    writeOpCode(unit: unit, code: code)
    writeByteOperand(unit: unit, operand: operand)
}

/// 写入操作数为2字节的指令
public func writeShortByteCode(unit: CompilerUnit, code: OP_CODE, operand: Int) {
    writeOpCode(unit: unit, code: code)
    writeShortOperand(unit: unit, operand: operand)
}


//MARK: EmitByteCode

/// 生成加载常量的指令
public func emitLoadConstant(unit: CompilerUnit, constant: AnyValue) {
    let index = unit.addConstant(constant: constant)
    writeShortByteCode(unit: unit,
                       code: .LOAD_CONSTANT,
                       operand: index)
}


/// 通过签名生成方法调用指令
public func emitCallBySignature(unit: CompilerUnit, signature: Signature, opCode: OP_CODE) {
    let name = signature.toString()
    emitCall(unit: unit, argsNum: signature.argNum, name: name)
    if opCode == .SUPER0 {
        writeShortOperand(unit: unit, operand: unit.addConstant(constant: AnyValue(value: nil)))
    }
}

/// 通过方法名生成调用指令
public func emitCall(unit: CompilerUnit, argsNum: Int, name: String) {
    let index = ensureSymbolExist(virtual: unit.curLexParser.virtual,
                                  symbolList: &unit.curLexParser.virtual.allMethodNames,
                                  name: name)
    if let opCode = OP_CODE(rawValue: OP_CODE.CALL0.rawValue + Byte(argsNum)) {
        writeShortByteCode(unit: unit,
                           code:opCode ,
                           operand: index)
    }
}

/// 为实参列表各个参数生成加载实参的指令
public func emitProcessArgList(unit: CompilerUnit, signature: Signature) throws {
    guard let token = unit.curLexParser.curToken else {
        throw BuildError.general(message: "Token为空")
    }
    guard token.type != .rightParen, token.type != .rightBracket else {
        throw BuildError.general(message: "参数列表为空")
    }
    repeat {
        if signature.argNum > maxArgNum {
            throw BuildError.general(message: "参数个数超过最大")
        }
        try! expression(unit: unit, rbp: .lowest)
    } while unit.curLexParser.matchCurToken(expected: .comma)
}

public func emitProcessParaList(unit: CompilerUnit, signature: Signature) throws {
    guard let token = unit.curLexParser.curToken else {
        throw BuildError.general(message: "Token为空")
    }
    guard token.type != .rightParen, token.type != .rightBracket else {
        throw BuildError.general(message: "参数列表为空")
    }
    
    repeat {
        if signature.argNum > maxArgNum {
            throw BuildError.general(message: "参数个数超过最大")
        }
        try! unit.curLexParser.consumeCurToken(expected: .id, message: "中缀运算符后非变量名")
        //TODO: 需要处理字面量值,比如数字等
        guard let name = unit.curLexParser.preToken?.value as? String else {
            throw BuildError.general(message: "参数非变量名")
        }
        unit.declareVariable(name: name)
    } while unit.curLexParser.matchCurToken(expected: .comma)
}

/// 生成加载变量到栈的指令
public func emitLoadVariable(unit: CompilerUnit, variable: Variable) {
    switch variable.type {
    case .local:
        writeByteCode(unit: unit,
                      code: OP_CODE.LOAD_LOCAL_VAR,
                      operand: variable.index)
    case .upvalue:
        writeByteCode(unit: unit,
                      code: OP_CODE.LOAD_UPVALUE,
                      operand: variable.index)
    case .module:
        writeByteCode(unit: unit,
                      code: OP_CODE.LOAD_MODULE_VAR,
                      operand: variable.index)
    default:
        break
    }
}

/// 生成从栈顶弹出数据到变量中存储的指令
public func emitStoreVariable(unit: CompilerUnit, variable: Variable) {
    switch variable.type {
    case .local:
        writeByteCode(unit: unit,
                      code: OP_CODE.STORE_LOCAL_VAR,
                      operand: variable.index)
    case .upvalue:
        writeByteCode(unit: unit,
                      code: OP_CODE.STORE_UPVALUE,
                      operand: variable.index)
    case .module:
        writeByteCode(unit: unit,
                      code: OP_CODE.STORE_MODULE_VAR,
                      operand: variable.index)
    default:
        break
    }
}

/// 生成加载或存储变量的指令
public func emitLoadOrStoreVariable(unit: CompilerUnit, assign: Bool, variable: Variable) {
    if assign && unit.curLexParser.matchCurToken(expected: .assign) {
        try! expression(unit: unit, rbp: .lowest)
        emitStoreVariable(unit: unit, variable: variable)
    } else {
        emitLoadVariable(unit: unit, variable: variable)
    }
}

public func emitLoadThis(unit: CompilerUnit) throws {
    guard let variable = unit.findVarFromLocalOrUpvalue(name: "this") else {
        throw BuildError.general(message: "加载变量this失败")
    }
    emitLoadVariable(unit: unit, variable: variable)
}

/// 生成gett或一般method调用指令
public func emitGetterMethodCall(unit: CompilerUnit, signature: Signature, code: OP_CODE) throws {
    let newSignature = Signature(type: .getter, name: signature.name, argNum: 0)
    
    if unit.curLexParser.matchCurToken(expected: .leftParen) {
        newSignature.type = .method
        if !unit.curLexParser.matchCurToken(expected: .rightParen) {
            try! emitProcessArgList(unit: unit, signature: newSignature)
            try! unit.curLexParser.consumeCurToken(expected: .rightParen, message: "参数后必须跟)")
        }
    }
    
    if unit.curLexParser.matchCurToken(expected: .leftBrace) {
        newSignature.type = .method
        newSignature.argNum += 1
        let internalUnit = CompilerUnit(lexParser: unit.curLexParser,
                                        enclosingUnit: unit,
                                        isMethod: false)
        let internalSignature = Signature(type: .method,
                                          name: "",
                                          argNum: 0)
        
        if unit.curLexParser.matchCurToken(expected: .bitOr) {
            try! emitProcessParaList(unit: unit, signature: internalSignature)
            try! unit.curLexParser.consumeCurToken(expected: .bitOr, message: "块参数后必须跟|")
        }
        internalUnit.fn.argNum = newSignature.argNum
        internalUnit.compileBody(isConstruct: false)
        internalUnit.endCompile()
    }
    if signature.type == .construct {
        guard newSignature.type == .method else {
            throw BuildError.general(message: "super的调用形式是super()或super(arguments)")
        }
        newSignature.type = .construct
    }
    emitCallBySignature(unit: unit,
                        signature: newSignature,
                        opCode: code)
}

/// 生成setter、getter或一般方法调用指令
public func emitMethodCall(unit: CompilerUnit, name: String, code: OP_CODE, assign: Bool) {
    let signature = Signature(type: .getter,
                              name: name,
                              argNum: 0)
    if assign && unit.curLexParser.matchCurToken(expected: .assign) {
        signature.type = .setter
        signature.argNum = 1 // setter只能接受一个参数
        try! expression(unit: unit, rbp: .lowest)
        emitCallBySignature(unit: unit,
                            signature: signature,
                            opCode: code)
    } else {
        try! emitGetterMethodCall(unit: unit,
                                  signature: signature,
                                  code: code)
    }
}


/// 生成数字和字符串.nud()字面量指令
public func emitLiteral(unit: CompilerUnit, canAssign: Bool) {
    emitLoadConstant(unit: unit, constant: AnyValue(value: unit.curLexParser.preToken?.value))
}


/// 生成加载类的指令
public func emitLoadModuleVar(unit: CompilerUnit, name: String) throws {
    let index = getIndexFromSymbolList(list: unit.curLexParser.curModule.vars, target: name)
    guard index >= 0 else {
        throw BuildError.general(message: "symbol should have been defined")
    }
    
    writeShortByteCode(unit: unit, code: OP_CODE.LOAD_MODULE_VAR, operand: index)
}

/// 编译内嵌表达式生成指令
public func emitStringInterpolation(unit: CompilerUnit, assgin: Bool) {
    /// a %(b+c) d%(e) f
    try! emitLoadModuleVar(unit: unit, name: "List")
    emitCall(unit: unit, argsNum: 0, name: "new()")
    
    repeat {
        emitLiteral(unit: unit, canAssign: false)
        try! expression(unit: unit, rbp: .lowest)
        emitCall(unit: unit, argsNum: 1, name: "addCore_()")
    } while unit.curLexParser.matchCurToken(expected: .interpolation)
    
    try! unit.curLexParser.consumeCurToken(expected: .string, message: "内嵌表达式应该在后面跟字符串")
    emitLiteral(unit: unit, canAssign: false)
    emitCall(unit: unit, argsNum: 1, name: "addCore_")
    emitCall(unit: unit, argsNum: 0, name: "join()")
}

/// 编译bool生成指令
public func emitBoolean(unit: CompilerUnit, assign: Bool) {
    var realType = Token.TokenType.false_
    if let type = unit.curLexParser.preToken?.type,type == .true_ {
        realType = type
    }
    writeOpCode(unit: unit, code: OP_CODE.PUSH_NULL)
}
///编译this生成指令
public func emitThis(unit: CompilerUnit, assign: Bool) throws {
    guard let _ = unit.getEnclosingClassBK() else {
        throw BuildError.general(message: "this must be inside method(no func)")
    }
    try! emitLoadThis(unit: unit)
}

public func emitSuper(unit: CompilerUnit, assign: Bool) throws {
    guard let enclosingBK = unit.getEnclosingClassBK() else {
        throw BuildError.general(message: "can`t invote super outdide a class method")
    }
    try! emitLoadThis(unit: unit)
    if unit.curLexParser.matchCurToken(expected: .dot) {
        try! unit.curLexParser.consumeCurToken(expected: .id, message: ".后必须跟变量名")
        emitMethodCall(unit: unit,
                       name: unit.curLexParser.preToken?.value as? String ?? "",
                       code: OP_CODE.SUPER0,
                       assign: assign)
    } else {
        try! emitGetterMethodCall(unit: unit,
                                  signature: enclosingBK.signature,
                                  code: OP_CODE.SUPER0)
    }
}




