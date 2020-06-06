//
//  Compile.swift
//  PoLang
//
//  Created by xuzhongping on 2020/5/24.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

// MARK: - Public methods
public func compileModule(context: RuntimeContext, module: ModuleInfo, code: String) -> FnInfo? {
    copyFromCoreModule(context: context, module: module)
    
    context.lexParser = LexParser(code: code)
    
    let moduleUnit = CompileUnit(context: context, enclosingUnit: nil, isMethod: false)
    
    context.lexParser.nextToken()
    
    while !context.lexParser.matchCurToken(expected: .eof) {
        compileProgram(unit: moduleUnit)
    }
    
    moduleUnit.writeOpCode(code: .PUSH_NULL)
    moduleUnit.writeOpCode(code: .RETURN)
    
    return endCompile(unit: moduleUnit)
}

public func compileProgram(unit: CompileUnit) {
    guard let lexParser = unit.context.lexParser else {
        fatalError()
    }
    if lexParser.matchCurToken(expected: .class_) {
//        compileClassDefinition(unit: unit)
        
    } else if lexParser.matchCurToken(expected: .func_) {
//        compileFunctionDefinition(unit: unit)
        
    } else if lexParser.matchCurToken(expected: .var_) {
//        let preToken = unit.curLexParser.preToken
//        compileVarDefinition(unit: unit, isStatic: preToken.type == .static_)
//
    } else if lexParser.matchCurToken(expected: .import_) {
//        compileImport(unit: unit)
        
    } else {
//        compileStatment(unit: unit)
    }
}

@discardableResult
public func endCompile(unit: CompileUnit) -> FnInfo {
    
    // 写入END指令表示本编译单元的指令结束了
    unit.writeOpCode(code: .END)

    // 当存在父编译单元，说明其为闭包
    if let enclosingUnit = unit.enclosingUnit {
        // 将当前编译单元的fn写入到父编译单元中作为常量
        unit.fn.upvalueNum = unit.upvalues.count
        let index = enclosingUnit.defineConst(value: Value(value: unit.fn))
        
        // 在父编译单元中写入指令创建闭包
        enclosingUnit.writeShortByteCode(code: .CREATE_CLOSURE, operand: index)
    
        // 写入所有upvalue
        for upvalue in unit.upvalues {
            // 1代表此upvalueIndex为直接外层函数中局部变量的索引，0代表为直接外层函数中upvalue的索引
            enclosingUnit.writeByte(byte: upvalue.isEnclosingLocalVar ? 1: 0)
            enclosingUnit.writeByte(byte: Byte(upvalue.index))
        }
    }
        
    return unit.fn
}


// MARK: - Private methods
private func copyFromCoreModule(context: RuntimeContext, module: ModuleInfo) {
    guard module.name != ModuleName.core else {
        return
    }
    
    let coreModule = context.loadCoreModule()
    for i in 0..<coreModule.moduleVarNames.count {
        module.defineModuleVar(coreModule.moduleVarNames[i], coreModule.moduleVarValues[i])
    }
}



