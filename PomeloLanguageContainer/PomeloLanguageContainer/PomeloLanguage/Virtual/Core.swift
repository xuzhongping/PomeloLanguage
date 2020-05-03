//
//  Core.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa



// MARK: Module

public func buildCore(virtual: Virtual) {
    
    
    let coreModule = ModuleObject(name: ModuleNameCore, virtual: virtual)
    
    let coreModuleCode = PoLoader.loadCore()
    
    virtual.allModules[ModuleNameCore] = AnyValue(value: coreModule)
    
    /// 创建Object类
    virtual.objectClass = ClassObject.defineClass(virtual: virtual, module: coreModule, name: ClassNameObject)
    
    /// 绑定原生方法
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "!", imp: nativeObjectNot(virtual:stack:argsStart:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "==(_)", imp: nativeObjectEqual(virtual:stack:argsStart:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "!=(_)", imp: nativeObjectNotEqual(virtual:stack:argsStart:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "is(_)", imp: nativeObjectIs(virtual:stack:argsStart:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "className(_)", imp: nativeObjectGetClassName(virtual:stack:argsStart:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "class(_)", imp: nativeObjectGetClass(virtual:stack:argsStart:))
    
    /// 创建Class类
   
    virtual.classOfClass =  ClassObject.defineClass(virtual: virtual, module: coreModule, name: ClassNameClass)
    
    /// 绑定原生方法
    virtual.classOfClass.bindNativeMethod(virtual: virtual, selector: "name", imp: nativeClassGetName(virtual:stack:argsStart:))
    virtual.classOfClass.bindNativeMethod(virtual: virtual, selector: "superClass", imp: nativeClassGetSuperClass(virtual:stack:argsStart:))
    
    /// 绑定基类
    virtual.classOfClass.bindSuperClass(virtual: virtual, superClass: virtual.objectClass)
    
    /// 创建ObjectMeta类
    let objectMetaClass = ClassObject.defineClass(virtual: virtual, module: coreModule, name: ClassNameObjectMeta)
    
    /// 绑定基类
    objectMetaClass.bindSuperClass(virtual: virtual, superClass: virtual.classOfClass)
    
    /// 绑定meta类
    virtual.objectClass.bindMetaClass(virtual: virtual, metaClass: objectMetaClass)
    
    objectMetaClass.bindMetaClass(virtual: virtual, metaClass: virtual.classOfClass)
    
    virtual.classOfClass.bindMetaClass(virtual: virtual, metaClass: virtual.classOfClass)
    
    executeModule(virtual: virtual, name: ModuleNameCore, code: coreModuleCode)
}

/// 获取一个模块
public func getModule(virtual: Virtual, name: String) -> ModuleObject? {
    return virtual.allModules[name]?.toModuleObject()
}


/// 获取核心模块
public func getCoreModule(virtual: Virtual) -> ModuleObject? {
    return getModule(virtual: virtual, name: ModuleNameCore)
}


/// 加载一个模块
public func loadModule(virtual: Virtual, name: String, code: String)  -> ThreadObject? {
    var module = getModule(virtual: virtual, name: name)

    if module == nil {
        module = ModuleObject(name: name, virtual: virtual)
        virtual.allModules[name] = AnyValue(value: module)
        guard let coreModule = getCoreModule(virtual: virtual) else {
            fatalError("core module is null")
        }
        for i in 0..<coreModule.moduleVarNames.count {
            let name = coreModule.moduleVarNames[i]
            let value = coreModule.moduleVarValues[i]
            module!.defineVar(virtual: virtual, name: name, value: value)
        }
    }
    
    let fnObj = compileModule(virtual: virtual, module: module!, code: code)
    let closureObj = ClosureObject(virtual: virtual, fn: fnObj)
    
    return ThreadObject(virtual: virtual, closure: closureObj)
}



@discardableResult
public func executeModule(virtual: Virtual, name: String, code: String) -> Virtual.result {
    guard let threadObject = loadModule(virtual: virtual, name: name, code: code) else {
        fatalError()
    }
    return virtual.executeInstruction(thread: threadObject)
}

/// 编译Module(一个Pomelo脚本文件)
public func compileModule(virtual: Virtual, module: ModuleObject, code: String) -> FnObject {
    var lexParser: LexParser
    if let name = module.name {
        lexParser = LexParser(virtual: virtual,
                              moduleName: name,
                              module: module,
                              code: code)
    } else {
        lexParser = LexParser(virtual: virtual,
                              moduleName: "core.script.inc",
                              module: module,
                              code: code)
    }
    
    let moduleUnit = CompilerUnit(lexParser: lexParser,
                                  enclosingUnit: nil,
                                  isMethod: false)
    lexParser.nextToken()
    
    while !lexParser.matchCurToken(expected: .eof) {
        compileProgram(unit: moduleUnit)
    }
    
//    print("there is something to do...")
//    exit(0)
    
    writeOpCode(unit: moduleUnit, code: .PUSH_NULL)
    writeOpCode(unit: moduleUnit, code: .RETURN)
    
    let moduleVarNumBefor = module.moduleVarValues.count
    for index in 0..<moduleVarNumBefor {
        if module.moduleVarValues[index].isPlaceholder() {
            let moduleVarName = module.moduleVarNames[index]
            fatalError("module variable '\(moduleVarName)' not defined!")
        }
    }
    
    return endCompile(unit: moduleUnit)
}

public func compileProgram(unit: CompilerUnit) {
    if unit.curLexParser.matchCurToken(expected: .class_) {
        compileClassDefinition(unit: unit)
        
    } else if unit.curLexParser.matchCurToken(expected: .func_) {
        compileFunctionDefinition(unit: unit)
        
    } else if unit.curLexParser.matchCurToken(expected: .var_) {
        guard let preToken = unit.curLexParser.preToken else {
            fatalError()
        }
        compileVarDefinition(unit: unit, isStatic: preToken.type == .static_)
        
    } else if unit.curLexParser.matchCurToken(expected: .import_) {
        compileImport(unit: unit)
    } else {
        compileStatment(unit: unit)
    }
}
