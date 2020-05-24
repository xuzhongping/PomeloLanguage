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
    
    
    
    
    return nil
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


