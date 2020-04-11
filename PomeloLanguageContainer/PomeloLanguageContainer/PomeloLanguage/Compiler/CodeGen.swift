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
public func emitProcessArgList(unit: CompilerUnit, signature: Signature) {
    guard let token = unit.curLexParser.curToken else {
        fatalError()
    }
    guard token.type != .rightParen, token.type != .rightBracket else {
        fatalError()
    }
    repeat {
        if signature.argNum > maxArgNum {
            fatalError()
        }
        expression(unit: unit, rbp: .lowest)
    } while unit.curLexParser.matchCurToken(expected: .comma)
}

public func emitProcessParaList(unit: CompilerUnit, signature: Signature)  {
    guard let token = unit.curLexParser.curToken else {
        fatalError()
    }
    guard token.type != .rightParen, token.type != .rightBracket else {
        fatalError()
    }
    
    repeat {
        if signature.argNum > maxArgNum {
            fatalError()
        }
        unit.curLexParser.consumeCurToken(expected: .id, message: "中缀运算符后非变量名")
        //TODO: 需要处理字面量值,比如数字等
        guard let name = unit.curLexParser.preToken?.value as? String else {
            fatalError()
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
        expression(unit: unit, rbp: .lowest)
        emitStoreVariable(unit: unit, variable: variable)
    } else {
        emitLoadVariable(unit: unit, variable: variable)
    }
}

public func emitLoadThis(unit: CompilerUnit)  {
    guard let variable = unit.findVarFromLocalOrUpvalue(name: "this") else {
        fatalError()
    }
    emitLoadVariable(unit: unit, variable: variable)
}

/// 生成gett或一般method调用指令
public func emitGetterMethodCall(unit: CompilerUnit, signature: Signature, code: OP_CODE)  {
    let newSignature = Signature(type: .getter, name: signature.name, argNum: 0)
    
    if unit.curLexParser.matchCurToken(expected: .leftParen) {
        newSignature.type = .method
        if !unit.curLexParser.matchCurToken(expected: .rightParen) {
            emitProcessArgList(unit: unit, signature: newSignature)
            unit.curLexParser.consumeCurToken(expected: .rightParen, message: "参数后必须跟)")
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
            emitProcessParaList(unit: unit, signature: internalSignature)
            unit.curLexParser.consumeCurToken(expected: .bitOr, message: "块参数后必须跟|")
        }
        internalUnit.fn.argNum = newSignature.argNum
        emitBody(unit: internalUnit, isConstruct: false)
        endCompile(unit: unit)
    }
    if signature.type == .construct {
        guard newSignature.type == .method else {
            fatalError()
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
        expression(unit: unit, rbp: .lowest)
        emitCallBySignature(unit: unit,
                            signature: signature,
                            opCode: code)
    } else {
        emitGetterMethodCall(unit: unit,
                                  signature: signature,
                                  code: code)
    }
}


/// 生成数字和字符串.nud()字面量指令
public func emitLiteral(unit: CompilerUnit, assign: Bool) {
    emitLoadConstant(unit: unit, constant: AnyValue(value: unit.curLexParser.preToken?.value))
}


/// 生成加载类的指令
public func emitLoadModuleVar(unit: CompilerUnit, name: String)  {
    let index = getIndexFromSymbolList(list: unit.curLexParser.curModule.vars, target: name)
    guard index >= 0 else {
        fatalError()
    }
    
    writeShortByteCode(unit: unit, code: OP_CODE.LOAD_MODULE_VAR, operand: index)
}

/// 编译内嵌表达式生成指令
public func emitStringInterpolation(unit: CompilerUnit, assgin: Bool) {
    /// a %(b+c) d%(e) f
    emitLoadModuleVar(unit: unit, name: "List")
    emitCall(unit: unit, argsNum: 0, name: "new()")
    
    repeat {
        emitLiteral(unit: unit, assign: false)
        expression(unit: unit, rbp: .lowest)
        emitCall(unit: unit, argsNum: 1, name: "addCore_()")
    } while unit.curLexParser.matchCurToken(expected: .interpolation)
    
    unit.curLexParser.consumeCurToken(expected: .string, message: "内嵌表达式应该在后面跟字符串")
    emitLiteral(unit: unit, assign: false)
    emitCall(unit: unit, argsNum: 1, name: "addCore_")
    emitCall(unit: unit, argsNum: 0, name: "join()")
}

/// 编译bool生成指令
public func emitBoolean(unit: CompilerUnit, assign: Bool) {
    let opCode = unit.curLexParser.preToken?.type == Token.TokenType.true_ ? OP_CODE.PUSH_TRUE: OP_CODE.PUSH_FALSE
    writeOpCode(unit: unit, code: opCode)
}

public func emitNull(unit: CompilerUnit, assign: Bool) {
    writeOpCode(unit: unit, code: OP_CODE.PUSH_NULL)
}
///编译this生成指令
public func emitThis(unit: CompilerUnit, assign: Bool)  {
    guard let _ = unit.getEnclosingClassBK() else {
        fatalError()
    }
    emitLoadThis(unit: unit)
}

public func emitSuper(unit: CompilerUnit, assign: Bool)  {
    guard let enclosingBK = unit.getEnclosingClassBK() else {
        fatalError()
    }
    emitLoadThis(unit: unit)
    if unit.curLexParser.matchCurToken(expected: .dot) {
        unit.curLexParser.consumeCurToken(expected: .id, message: ".后必须跟变量名")
        emitMethodCall(unit: unit,
                       name: unit.curLexParser.preToken?.value as? String ?? "",
                       code: OP_CODE.SUPER0,
                       assign: assign)
    } else {
        emitGetterMethodCall(unit: unit,
                                  signature: enclosingBK.signature,
                                  code: OP_CODE.SUPER0)
    }
}

/// 中缀运算符.led方法
public func emitInfixOperator(unit: CompilerUnit, assign: Bool) {
    guard let curToken = unit.curLexParser.curToken else {
        return
    }
    guard let rule = SymbolBindRule.rulues[curToken.type] else {
        return
    }
    let rbp = rule.lbp
    expression(unit: unit, rbp: rbp)
    
    let signature = Signature(type: .method, name: rule.symbol ?? "", argNum: 1)
    emitCallBySignature(unit: unit, signature: signature, opCode: OP_CODE.CALL0)
}

/// 前缀运算符.nud方法，如-、!等
public func emitUnaryOperator(unit: CompilerUnit, assign: Bool) {
    guard let curToken = unit.curLexParser.curToken else {
        return
    }
    guard let rule = SymbolBindRule.rulues[curToken.type] else {
        return
    }
    expression(unit: unit, rbp: SymbolBindRule.BindPower.unary)
    emitCall(unit: unit, argsNum: 0, name: rule.symbol ?? "")
}


//MARK: Compile
/// 编译标识符
public func emitId(unit: CompilerUnit, assign: Bool) {
    guard let token = unit.curLexParser.preToken else {
        fatalError()
    }
    guard let value = token.value as? String else {
        fatalError()
    }
    
    /// 处理为函数调用
    if unit.enclosingUnit == nil && unit.curLexParser.matchCurToken(expected: .leftParen) {
        
        let name = "Fn \(value)"
        let index = getIndexFromSymbolList(list: unit.curLexParser.curModule.vars, target: name)
        guard index >= 0 else {
            fatalError()
        }
        
        emitLoadVariable(unit: unit, variable: Variable(type: .module, index: index))
        
        let signature = Signature(type: .method, name: "call", argNum: 0)
        if !unit.curLexParser.matchCurToken(expected: .rightParen) {
            emitProcessArgList(unit: unit, signature: signature)
            unit.curLexParser.consumeCurToken(expected: .rightParen, message: "参数列表后要跟)")
        }
        emitCallBySignature(unit: unit,
                            signature: signature,
                            opCode: OP_CODE.CALL0)
        return
    }

    /// 处理为局部变量何upvalue
    if let variable = unit.findVarFromLocalOrUpvalue(name: value) {
        emitLoadOrStoreVariable(unit: unit,
                                assign: assign,
                                variable: variable)
        return
    }
    
    /// 处理为实例域
    if let classBK = unit.getEnclosingClassBK() {
        let index = getIndexFromSymbolList(list: classBK.fields, target: value)
        if index >= 0 {
            var read = true
            if assign && unit.curLexParser.matchCurToken(expected: .assign) {
                read = false
                expression(unit: unit, rbp: .lowest)
            }
            /// 方法内或方法外引用域
            if let _ = unit.enclosingUnit {
                writeByteCode(unit: unit,
                              code: read ? OP_CODE.LOAD_THIS_FIELD: OP_CODE.STORE_THIS_FIELD,
                              operand: index)
            } else {
                emitLoadThis(unit: unit)
                writeByteCode(unit: unit,
                              code: read ? OP_CODE.LOAD_FIELD: OP_CODE.STORE_FIELD,
                              operand: index)
            }
            return
        }
    }
    
    /// 处理为静态域
    if let classBK = unit.getEnclosingClassBK() {
        let name = "Cls\(classBK.name) \(value)"
        if let variable = unit.findVarFromLocalOrUpvalue(name: name) {
            emitLoadOrStoreVariable(unit: unit,
                                    assign: assign,
                                    variable: variable)
            return
        }
    }
    
    /// 处理为一般方法调用
    if let _ = unit.getEnclosingClassBK(), value.firstIsLowercase() {
        emitLoadThis(unit: unit)
        emitMethodCall(unit: unit,
                       name: value,
                       code: OP_CODE.CALL0,
                       assign: assign)
        return
    }

    /// 处理为模块变量
    var index = getIndexFromSymbolList(list: unit.curLexParser.curModule.vars, target: value)
    if index == IndexNotFound {
        let name = "Fn \(value)"
        index = getIndexFromSymbolList(list: unit.curLexParser.curModule.vars, target: name)
        if index == IndexNotFound {
            index = unit.curLexParser.curModule.declareModuleVar(virtual: unit.curLexParser.virtual,
                                                            name: name,
                                                            value: AnyValue(value: unit.curLexParser.line))
            emitLoadOrStoreVariable(unit: unit,
                                    assign: assign,
                                    variable: Variable(type: .module, index: index))
            return
        }
    }
    emitLoadOrStoreVariable(unit: unit,
                            assign: assign,
                            variable: Variable(type: .module, index: index))
}

public func emitBlock(unit: CompilerUnit)  {
    while true {
        if unit.curLexParser.matchCurToken(expected: .rightBrace) {
            break
        }
        if unit.curLexParser.status == LexParser.LexStatus.end {
            fatalError()
        }
        unit.compileProgram()
    }
}

public func emitBody(unit: CompilerUnit, isConstruct: Bool) {
    emitBlock(unit: unit)
    if isConstruct {
        writeByteCode(unit: unit,
                      code: OP_CODE.LOAD_LOCAL_VAR,
                      operand: 0)
    } else {
        writeOpCode(unit: unit, code: OP_CODE.PUSH_NULL)
    }
    writeOpCode(unit: unit, code: OP_CODE.RETURN)
}

public func emitParentheses(unit: CompilerUnit, assign: Bool) {
    expression(unit: unit, rbp: .lowest)
    unit.curLexParser.consumeCurToken(expected: .rightParen, message: "(表达式后必须跟)")
}

public func emitListLiteral(unit: CompilerUnit, assgin: Bool)  {
    emitLoadModuleVar(unit: unit, name: "List")
    emitCall(unit: unit, argsNum: 0, name: "new()")
    while true {
        guard let token = unit.curLexParser.curToken else {
            fatalError()
        }
        if token.type == Token.TokenType.rightBracket {
            break
        }
        expression(unit: unit, rbp: .lowest)
        emitCall(unit: unit, argsNum: 1, name: "addCore_()")
        guard unit.curLexParser.matchCurToken(expected: .comma) else { break }
    }
}

public func emitSubscript(unit: CompilerUnit, assign: Bool)  {
    if unit.curLexParser.matchCurToken(expected: .rightBracket) {
        fatalError()
    }
    let signature = Signature(type: .subscriptGetter, name: "", argNum: 0)
    emitProcessArgList(unit: unit, signature: signature)
    unit.curLexParser.consumeCurToken(expected: .rightBracket, message: "[表达式后必须跟]")
    if assign && unit.curLexParser.matchCurToken(expected: .assign) {
        signature.type = .subscriptSetter
        signature.argNum += 1
        if signature.argNum > maxArgNum {
            fatalError()
        }
        expression(unit: unit, rbp: .lowest)
    }
    emitCallBySignature(unit: unit, signature: signature, opCode: OP_CODE.CALL0)
}

/// 编译方法调用入口，所有调用的入口
public func emitCallEntry(unit: CompilerUnit, assign: Bool)  {
    unit.curLexParser.consumeCurToken(expected: .id, message: "expect method name after '.'!")
    guard let name = unit.curLexParser.curToken?.value as? String else {
        fatalError()
    }
    emitMethodCall(unit: unit, name: name, code: OP_CODE.CALL0, assign: assign)
}

/// 编译map对象字面量
public func emitMapLiteral(unit: CompilerUnit, assign: Bool)  {
    emitLoadModuleVar(unit: unit, name: "Map")
    emitCall(unit: unit, argsNum: 0, name: "new()")
    while true {
        guard let token = unit.curLexParser.curToken else {
            fatalError()
        }
        if token.type == .rightBrace {
            break
        }
        expression(unit: unit, rbp: .unary)
        unit.curLexParser.consumeCurToken(expected: .colon, message: "expect ':' after key!")
        expression(unit: unit, rbp: .lowest)
        emitCall(unit: unit, argsNum: 2, name: "addCore_(_,_)")
        
        guard unit.curLexParser.matchCurToken(expected: .comma) else { break }
    }
    
    unit.curLexParser.consumeCurToken(expected: .rightBrace, message: "map literal should end with ')'!")
}

/// 生成用占位符作为参数设置指令
public func emitInstrWithPlaceholder(unit: CompilerUnit, opCode: OP_CODE) -> Int {
    writeOpCode(unit: unit, code: opCode)
    writeByte(unit: unit, byte: 0xFF)
    return writeByte(unit: unit, byte: 0xFF) - 1
}

/// 用跳转到当前字节码结束地址的偏移量去替换占位符参数0xffff
public func emitPatchPlaceholder(unit: CompilerUnit, absIndex: Int) {
    let offset = unit.fn.byteStream.count - absIndex - 2
    unit.fn.byteStream[absIndex] = Byte((offset >> 8) & 0xFF)
    unit.fn.byteStream[absIndex + 1] = Byte(offset & 0xFF)
}

public func emitLogicOr(unit: CompilerUnit, assign: Bool) {
    let placeholderIndex = emitInstrWithPlaceholder(unit: unit, opCode: .OR)
    expression(unit: unit, rbp: .logic_or)
    emitPatchPlaceholder(unit: unit, absIndex: placeholderIndex)
}

public func emitLogicAnd(unit: CompilerUnit, assign: Bool) {
    let placeholderIndex = emitInstrWithPlaceholder(unit: unit, opCode: .AND)
    expression(unit: unit, rbp: .logic_and)
    emitPatchPlaceholder(unit: unit, absIndex: placeholderIndex)
}

public func emitCondition(unit: CompilerUnit, assign: Bool) {
    let falseBranchStart = emitInstrWithPlaceholder(unit: unit, opCode: .JUMP_IF_FALSE)
    expression(unit: unit, rbp: .lowest)
    unit.curLexParser.consumeCurToken(expected: .colon, message: "expect ':' after true branch")
    let falseBranchEnd = emitInstrWithPlaceholder(unit: unit, opCode: .JUMP)
    
    emitPatchPlaceholder(unit: unit, absIndex: falseBranchStart)
    expression(unit: unit, rbp: .lowest)
    emitPatchPlaceholder(unit: unit, absIndex: falseBranchEnd)
}

public func emitVarDefinition(unit: CompilerUnit, isStatic: Bool)  {
    unit.curLexParser.consumeCurToken(expected: .id, message: "missing variable name!")
    guard let name = unit.curLexParser.preToken?.value as? String else {
        fatalError()
    }
    guard let token = unit.curLexParser.curToken else {
        fatalError()
    }
    if token.type == .comma {
        fatalError()
    }
    
    // 在类中
    if let enclosingClassBK = unit.enclosingClassBK, unit.enclosingUnit == nil {
        // 静态域类
        if isStatic {
            let localName = "Cls \(enclosingClassBK.name) \(name)"
            if unit.findLocalVar(name: localName) == IndexNotFound {
                let index = unit.declareLocalVar(name: localName)
                writeOpCode(unit: unit, code: .PUSH_NULL)
                guard unit.scopeDepth == 0 else {
                    fatalError()
                }
                unit.defineVariable(index: index)
                guard let variable = unit.findVarFromLocalOrUpvalue(name: localName) else {
                    fatalError()
                }
                if unit.curLexParser.matchCurToken(expected: .assign) {
                    expression(unit: unit, rbp: .lowest)
                    emitStoreVariable(unit: unit, variable: variable)
                }
            } else {
                fatalError()
            }
        } else {
            // 实例域
            guard let classBK = unit.getEnclosingClassBK() else {
                fatalError()
            }
            var fieldIndex = getIndexFromSymbolList(list: classBK.fields, target: name)
            if fieldIndex == IndexNotFound {
//                fieldIndex =
            } else {
                if fieldIndex > maxFieldNum {
                    fatalError()
                } else {
                    fatalError()
                }
            }
            
            if unit.curLexParser.matchCurToken(expected: .assign) {
                fatalError()
            }
        }
        return
    }
    
    // 不在类中，按模块中普通变量定义
    
    if unit.curLexParser.matchCurToken(expected: .assign) {
        expression(unit: unit, rbp: .lowest)
    } else {
        writeOpCode(unit: unit, code: .PUSH_NULL)
    }
    let index = unit.declareLocalVar(name: name)
    unit.defineVariable(index: index)
}

/// 结束当前编译单元的编译工作
/// 当存在外层编译单元时，内层编译单元为外层的闭包
@discardableResult
public func endCompile(unit: CompilerUnit) -> FnObject {
    writeOpCode(unit: unit, code: OP_CODE.END)
    if let enclosingUnit = unit.enclosingUnit {
        let index = enclosingUnit.addConstant(constant: AnyValue(value: unit.fn))
        writeShortByteCode(unit: enclosingUnit,
                           code: OP_CODE.CREATE_CLOSURE,
                           operand: index)
        
        for upvalue in unit.upvalues {
            writeByte(unit: enclosingUnit, byte: upvalue.isEnclosingLocalVar ? 1: 0)
            writeByte(unit: enclosingUnit, byte: Byte(upvalue.index))
        }
    }
    unit.curLexParser.curCompileUnit = unit.enclosingUnit
    return unit.fn
}
