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
    
//    import foo
//
//    编译为:
//
//    System.importModule("foo")
//
//    import foo for bar1, bar2
//
//    编译为:
//
//    var bar1 = System.getModuleVariable("foo", "bar1")
//    var bar2 = System.getModuleVariable("foo", "bar2")
    
    unit.curLexParser.consumeCurToken(expected: .id, message: "expect module name after export!")
    
    guard let moduleName = unit.curLexParser.preToken?.value as? String else {
        fatalError()
    }
    
    if let value = unit.curLexParser.curToken?.value as? String, value == "." {
        unit.curLexParser.nextToken()
        unit.curLexParser.nextToken()
    }
    
    let moduleNameIndex = unit.addConstant(constant: AnyValue(value: moduleName))
    
    emitLoadModuleVar(unit: unit, name: "System")
    writeShortByteCode(unit: unit, code: .LOAD_CONSTANT, operand: moduleNameIndex)
    emitCall(unit: unit, argsNum: 1, name: "importModule(_)")
    
    writeOpCode(unit: unit, code: .POP)

    guard unit.curLexParser.matchCurToken(expected: .for_) else {
        return
    }
    
    // 循环编译导入的模块变量，以逗号分隔
    while true {
        unit.curLexParser.consumeCurToken(expected: .id, message: "expect variable name after 'for' in import!")
        guard let varName = unit.curLexParser.preToken?.value as? String else {
            fatalError()
        }
        let varIndex = unit.declareVariable(name: varName)
        let varNameIndex = unit.addConstant(constant: AnyValue(value: varName))
        
        emitLoadModuleVar(unit: unit, name: "System")
        writeShortByteCode(unit: unit, code: .LOAD_CONSTANT, operand: moduleNameIndex)
        writeShortByteCode(unit: unit, code: .LOAD_CONSTANT, operand: varNameIndex)
        
        emitCall(unit: unit, argsNum: 2, name: "getModuleVariable(_,_)")
        unit.defineVariable(index: varIndex)
        
        guard unit.curLexParser.matchCurToken(expected: .comma) else { break }
    }
}
