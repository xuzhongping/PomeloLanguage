//
//  CodeGenModule.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/4/11.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

/// 编译import导入模块或导入模块变量
func compileImport(unit: CompilerUnit) {
    unit.curLexParser.consumeCurToken(expected: .id, message: "expect module name after export!")
    guard let moduleName = unit.curLexParser.preToken?.value as? String else {
        fatalError()
    }
    guard let value = unit.curLexParser.curToken?.value as? String else {
        fatalError()
    }
    
    // 跳过扩展名
    if value == "." {
        unit.curLexParser.nextToken()
        unit.curLexParser.nextToken()
    }
    
    let constIndex = unit.addConstant(constant: AnyValue(value: moduleName))
    
    emitLoadModuleVar(unit: unit, name: "System")
    writeShortByteCode(unit: unit, code: .LOAD_CONSTANT, operand: constIndex)
    emitCall(unit: unit, argsNum: 1, name: "importModule(_)")
    
    writeOpCode(unit: unit, code: .POP)

    guard unit.curLexParser.matchCurToken(expected: .for_) else {
        return
    }
    
    // 循环编译导入的模块变量，以逗号分隔
    while true {
        unit.curLexParser.consumeCurToken(expected: .id, message: "expect variable name after 'for' in import!")
        guard let name = unit.curLexParser.preToken?.value as? String else {
            fatalError()
        }
        let tVarIndex = unit.declareVariable(name: name)
        let tConstIndex = unit.addConstant(constant: AnyValue(value: name))
        emitLoadModuleVar(unit: unit, name: "System")
        writeShortByteCode(unit: unit, code: .LOAD_CONSTANT, operand: constIndex)
        writeShortByteCode(unit: unit, code: .LOAD_CONSTANT, operand: tConstIndex)
        emitCall(unit: unit, argsNum: 2, name: "getModuleVariable(_,_)")
        unit.defineVariable(index: tVarIndex)
        
        guard unit.curLexParser.matchCurToken(expected: .comma) else { break }
    }
}
