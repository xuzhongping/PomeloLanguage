//
//  CodeGenObject.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/4/11.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

/// 生成存储模块变量的指令
func emitStoreModuleVar(unit: CompilerUnit, index: Int) {
    writeShortByteCode(unit: unit, code: .STORE_MODULE_VAR, operand: index)
    writeOpCode(unit: unit, code: .POP)
}


/// 声明方法
func declareMethod(unit: CompilerUnit, signStr: String) -> Int {
    let index = ensureSymbolExist(virtual: unit.curLexParser.virtual, symbolList: &unit.curLexParser.virtual.allMethodNames, name: signStr)
    
    // 判断方法是否重复定义
    guard let enclosingClassBK = unit.enclosingClassBK else {
        fatalError()
    }
    var methods = enclosingClassBK.inStatic ? enclosingClassBK.staticMethods : enclosingClassBK.instanceMethods
    if methods.contains(index) {
        fatalError()
    }
    
    methods.append(index)
    return index
}

/// 将方法索引指代的方法装入classVar指代的class.methods中
func defineMethod(unit: CompilerUnit, classVar: Variable, isStatic: Bool, methodIndex: Int) {
    emitLoadVariable(unit: unit, variable: classVar)
    let opCode = isStatic ? OP_CODE.STATIC_METHOD : OP_CODE.INSTANCE_METHOD
    writeShortByteCode(unit: unit, code: opCode, operand: methodIndex)
}

/// 给构造函数生成静态方法
func emitCreateInstance(unit: CompilerUnit, sign: Signature, constructorIndex: Int) {
    let methodUnit = CompilerUnit(lexParser: unit.curLexParser, enclosingUnit: unit, isMethod: true)
    writeOpCode(unit: methodUnit, code: .CONSTRUCT)
    guard let opCode = OP_CODE(rawValue: Byte(Int(OP_CODE.CALL0.rawValue) + sign.argNum)) else {
        fatalError()
    }
    writeShortByteCode(unit: methodUnit,
                       code: opCode,
                       operand: constructorIndex)
    writeOpCode(unit: unit, code: .RETURN)
    endCompile(unit: unit)
}

/// 编译方法定义
func compileMethodDefinition(unit: CompilerUnit, classVar: Variable, isStatic: Bool) {
    guard let token = unit.curLexParser.curToken else {
        fatalError()
    }
    guard let name = token.value as? String else {
        fatalError()
    }
    
    guard let enclosingClassBK = unit.enclosingClassBK else {
        fatalError()
    }
    
    guard let methodSign = SymbolBindRule.rulues[token.type]?.methodSignature else {
        fatalError("method need signature function!")
    }
    
    enclosingClassBK.inStatic = isStatic
    
    let sign = Signature(type: .getter, name: name, argNum: 0)
    unit.enclosingClassBK?.signature = sign
    unit.curLexParser.nextToken()
    
    let methodUnit = CompilerUnit(lexParser: unit.curLexParser,
                                  enclosingUnit: unit,
                                  isMethod: true)
    methodSign(methodUnit, sign)
    
    unit.curLexParser.consumeCurToken(expected: .leftBrace, message: "expect '{' at the beginning of method body.")
    
    if enclosingClassBK.inStatic && sign.type == .construct {
        fatalError("constuctor is not allowed to be static!")
    }
    
    let methodIndex = declareMethod(unit: unit, signStr: sign.toString())
    emitBody(unit: unit, isConstruct: sign.type == .construct)
    
    endCompile(unit: unit)
    
    defineMethod(unit: unit,
                 classVar: classVar,
                 isStatic: enclosingClassBK.inStatic,
                 methodIndex: methodIndex)
    
    if sign.type == .construct {
        sign.type = .method
        let constructorIndex = ensureSymbolExist(virtual: unit.curLexParser.virtual,
                                                 symbolList: &unit.curLexParser.virtual.allMethodNames,
                                                 name: sign.toString())
        emitCreateInstance(unit: unit,
                           sign: sign,
                           constructorIndex: methodIndex)
        defineMethod(unit: unit, classVar: classVar, isStatic: true, methodIndex: constructorIndex)
    }
}

/// 编译类体
func compileClassBody(unit: CompilerUnit, classVar: Variable) {
    if unit.curLexParser.matchCurToken(expected: .static_) {
        if unit.curLexParser.matchCurToken(expected: .var_) {
            emitVarDefinition(unit: unit, isStatic: true)
        } else {
            compileMethodDefinition(unit: unit, classVar: classVar, isStatic: true)
        }
    } else if unit.curLexParser.matchCurToken(expected: .var_) {
        emitVarDefinition(unit: unit, isStatic: false)
    } else {
        compileMethodDefinition(unit: unit, classVar: classVar, isStatic: false)
    }
}

/// 编译类定义
func compileClassDefinition(unit: CompilerUnit) {
    guard unit.scopeDepth == -1 else {
        fatalError("class definition must be in the module scope!")
    }
    unit.curLexParser.consumeCurToken(expected: .id, message: "keyword class should follow by class name!")
    guard let className = unit.curLexParser.preToken?.value as? String else {
        fatalError()
    }
    let index = unit.declareVariable(name: className)
    let classVar = Variable(type: .module, index: index)
    emitLoadConstant(unit: unit, constant: AnyValue(value: className))
    
    if unit.curLexParser.matchCurToken(expected: .less) {
        expression(unit: unit, rbp: .call)
    } else {
        emitLoadModuleVar(unit: unit, name: "object")
    }
    
    let filedNumIndex = writeByteCode(unit: unit, code: .CREATE_CLASS, operand: 255)
    if unit.scopeDepth == -1 {
        emitStoreModuleVar(unit: unit, index: classVar.index)
    }
    let classBK = ClassBookKeep(name: className)
    unit.enclosingClassBK = classBK
    
    unit.curLexParser.consumeCurToken(expected: .leftBrace, message: "expect '{' after class name in the class declaration!")
    
    enterScope(unit: unit)
    
    while !unit.curLexParser.matchCurToken(expected: .rightBrace) {
        compileClassBody(unit: unit, classVar: classVar)
        guard let _ = unit.curLexParser.curToken else {
            fatalError()
        }
    }
    
    unit.fn.byteStream[filedNumIndex] = Byte(classBK.fields.count)
    classBK.fields.removeAll()
    classBK.instanceMethods.removeAll()
    classBK.staticMethods.removeAll()
    
    unit.enclosingClassBK = nil
    leaveScope(unit: unit)
}

/// 编译函数定义
func compileFunctionDefinition(unit: CompilerUnit) {
    if let _ = unit.enclosingUnit {
        fatalError("'fun' should be in module scope!")
    }
    unit.curLexParser.consumeCurToken(expected: .id, message: "missing function name!")
    guard let name = unit.curLexParser.preToken?.value as? String else {
        fatalError()
    }
    let fnName = "Fn \(name)"
    let fnNameIndex = unit.declareLocalVar(name: fnName)
    let fnUnit = CompilerUnit(lexParser: unit.curLexParser, enclosingUnit: unit, isMethod: false)
    let tempFnSign = Signature(type: .method, name: "", argNum: 0)
    unit.curLexParser.consumeCurToken(expected: .leftParen, message: "expect '(' after function name!")
    
    if !unit.curLexParser.matchCurToken(expected: .rightParen) {
        emitProcessParaList(unit: unit, signature: tempFnSign)
        unit.curLexParser.consumeCurToken(expected: .rightParen, message: "expect ')' after parameter list!")
    }
    
    fnUnit.fn.argNum = tempFnSign.argNum
    unit.curLexParser.consumeCurToken(expected: .leftBrace, message: "expect '{' at the beginning of method body!")
    emitBody(unit: fnUnit, isConstruct: false)
    
    endCompile(unit: unit)
    unit.defineVariable(index: fnNameIndex)
}

