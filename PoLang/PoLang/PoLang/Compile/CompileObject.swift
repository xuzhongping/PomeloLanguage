//
//  CompileObject.swift
//  PoLang
//
//  Created by 徐仲平 on 2020/6/6.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public func compileClassDefinition(unit: CompileUnit) {
    guard unit.scopeDepth == ScopeDepth.module else {
        fatalError("类必须定义在模块作用域中!")
    }
    unit.context.lexParser.consumeCurToken(expected: .id, message: "类名必须为id token!")
    guard let clsName = unit.context.lexParser.preToken.value as? String else {
        fatalError()
    }
    let constIndex = unit.defineConst(value: Value(value: clsName))
    unit.emitLoadConst(index: constIndex)
    
    if unit.context.lexParser.matchCurToken(expected: .less) {
        
    } else {
        guard let moduleVarIndex = unit.context.module.moduleVarNames.firstIndex(of: ClassName.object) else {
            fatalError("未找到类\(ClassName.object)")
        }
        let variable = Variable(type: .module, index: moduleVarIndex)
        unit.emitLoadVariable(variable: variable)
    }
    let index = unit.declareVariable(name: clsName)
    let clsVar = Variable(type: .module, index: index)
    let fieldNumIndex = unit.writeByteCode(code: .CREATE_CLASS, operand: 255)
    if unit.scopeDepth == ScopeDepth.module {
        unit.emitStoreVariable(variable: Variable(type: .module, index: clsVar.index))
        unit.writeOpCode(code: .POP)
    }
    let clsBk = ClassBookKeep(name: clsName)
    unit.enclosingClassBK = clsBk
    unit.context.lexParser.consumeCurToken(expected: .leftBrace, message: "类定义缺少大括号{!")
}
