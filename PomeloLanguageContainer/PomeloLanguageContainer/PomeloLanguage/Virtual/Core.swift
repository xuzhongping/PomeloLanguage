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
    
    let coreModule = ModuleObject(name: ModuleName.core, virtual: virtual)
    
    let coreModuleCode = Loader.loadCoreModule()
    
    virtual.allModules[ModuleName.core] = AnyValue(value: coreModule)
    
    /// 创建Object类
    virtual.objectClass = ClassObject.defineClass(virtual: virtual, module: coreModule, name: ClassName.object)
    
    /// 绑定原生方法
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "!", imp: nativeObjectNot(virtual:stack:argsStart:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "==(_)", imp: nativeObjectEqual(virtual:stack:argsStart:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "!=(_)", imp: nativeObjectNotEqual(virtual:stack:argsStart:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "is(_)", imp: nativeObjectIs(virtual:stack:argsStart:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "className(_)", imp: nativeObjectGetClassName(virtual:stack:argsStart:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "class(_)", imp: nativeObjectGetClass(virtual:stack:argsStart:))
    
    /// 创建Class类
   
    virtual.classOfClass =  ClassObject.defineClass(virtual: virtual, module: coreModule, name: ClassName.cls)
    
    /// 绑定原生方法
    virtual.classOfClass.bindNativeMethod(virtual: virtual, selector: "name", imp: nativeClassGetName(virtual:stack:argsStart:))
    virtual.classOfClass.bindNativeMethod(virtual: virtual, selector: "superClass", imp: nativeClassGetSuperClass(virtual:stack:argsStart:))
    
    /// 绑定基类
    virtual.classOfClass.bindSuperClass(virtual: virtual, superClass: virtual.objectClass)
    
    /// 创建ObjectMeta类
    let objectMetaClass = ClassObject.defineClass(virtual: virtual, module: coreModule, name: ClassName.metaObject)
    
    /// 绑定基类
    objectMetaClass.bindSuperClass(virtual: virtual, superClass: virtual.classOfClass)
    
    /// 绑定meta类
    virtual.objectClass.bindMetaClass(virtual: virtual, metaClass: objectMetaClass)
    
    objectMetaClass.bindMetaClass(virtual: virtual, metaClass: virtual.classOfClass)
    
    virtual.classOfClass.bindMetaClass(virtual: virtual, metaClass: virtual.classOfClass)
    
    
    executeModule(virtual: virtual, name: ModuleName.core, code: coreModuleCode)
    
    
    guard let boolClassObject = getClassFromModule(module: coreModule, name: "Bool") else {
        fatalError()
    }
    virtual.boolClass = boolClassObject
    virtual.boolClass.bindNativeMethod(virtual: virtual, selector: "toString", imp: nativeBoolToString(virtual:stack:argsStart:))
    virtual.boolClass.bindNativeMethod(virtual: virtual, selector: "!", imp: nativeBoolNot(virtual:stack:argsStart:))
    
    guard let threadClassObject = getClassFromModule(module: coreModule, name: "Thread") else {
        fatalError()
    }
    virtual.threadClass = threadClassObject
    virtual.threadClass.header.cls?.bindNativeMethod(virtual: virtual, selector: "new(_)", imp: nativeThreadNew(virtual:stack:argsStart:))
    virtual.threadClass.header.cls?.bindNativeMethod(virtual: virtual, selector: "abort(_)", imp: nativeThreadAbort(virtual:stack:argsStart:))
    virtual.threadClass.header.cls?.bindNativeMethod(virtual: virtual, selector: "current", imp: nativeThreadCurrent(virtual:stack:argsStart:))
    virtual.threadClass.header.cls?.bindNativeMethod(virtual: virtual, selector: "suspend()", imp: nativeThreadSuspend(virtual:stack:argsStart:))
    virtual.threadClass.header.cls?.bindNativeMethod(virtual: virtual, selector: "yield(_)", imp: nativeThreadYieldWithArg(virtual:stack:argsStart:))
    virtual.threadClass.header.cls?.bindNativeMethod(virtual: virtual, selector: "yield()", imp: nativeThreadYieldWithoutArg(virtual:stack:argsStart:))
    
    virtual.threadClass.bindNativeMethod(virtual: virtual, selector: "call()", imp: nativeThreadCallWithoutArg(virtual:stack:argsStart:))
    virtual.threadClass.bindNativeMethod(virtual: virtual, selector: "call(_)", imp: nativeThreadCallWithArg(virtual:stack:argsStart:))
    virtual.threadClass.bindNativeMethod(virtual: virtual, selector: "isDone", imp: nativeThreadIsDone(virtual:stack:argsStart:))
    
    guard let fnClassObject = getClassFromModule(module: coreModule, name: "Fn") else {
        fatalError()
    }
    virtual.fnClass = fnClassObject
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call()")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_,_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_,_,_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_,_,_,_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_,_,_,_,_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)")
    virtual.fnClass.bindFnOverloadCall(virtual: virtual, selector: "call(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)")
    
    guard let nullClassObject = getClassFromModule(module: coreModule, name: "Null") else {
        fatalError()
    }
    virtual.nullClass = nullClassObject
    nullClassObject.bindNativeMethod(virtual: virtual, selector: "!", imp: nativeNullNot(virtual:stack:argsStart:))
    nullClassObject.bindNativeMethod(virtual: virtual, selector: "toString", imp: nativeNullToString(virtual:stack:argsStart:))
    
    guard let numClassObject = getClassFromModule(module: coreModule, name: "Num") else {
        fatalError()
    }
    virtual.numClass = numClassObject
    virtual.numClass.header.cls?.bindNativeMethod(virtual: virtual, selector: "fromString(_)", imp: nativeNumFromString(virtual:stack:argsStart:))
    virtual.numClass.header.cls?.bindNativeMethod(virtual: virtual, selector: "pi", imp: nativeNumPi(virtual:stack:argsStart:))

    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "+(_)", imp: nativeNumPlus(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "-(_)", imp: nativeNumMinus(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "*(_)", imp: nativeNumMul(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "/(_)", imp: nativeNumDiv(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: ">(_)", imp: nativeNumGt(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: ">=(_)", imp: nativeNumGe(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "<(_)", imp: nativeNumLt(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "<=(_)", imp: nativeNumLe(virtual:stack:argsStart:))
    
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "&(_)", imp: nativeNumBitAnd(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "|(_)", imp: nativeNumBitOr(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "<<(_)", imp: nativeNumBitShiftLeft(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: ">>(_)", imp: nativeNumBitShiftRight(virtual:stack:argsStart:))
    
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "abs", imp: nativeNumAbs(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "acos", imp: nativeNumAcos(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "asin", imp: nativeNumAsin(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "atan", imp: nativeNumAtan(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "ceil", imp: nativeNumCeil(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "cos", imp: nativeNumCos(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "floor", imp: nativeNumFloor(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "-", imp: nativeNumNegate(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "sin", imp: nativeNumSin(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "sqrt", imp: nativeNumSqrt(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "tan", imp: nativeNumTan(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "%(_)", imp: nativeNumMod(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "~", imp: nativeNumBitNot(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "..(_)", imp: nativeNumRange(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "atan(_)", imp: nativeNumAtan2(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "fraction", imp: nativeNumFraction(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "isInfinity", imp: nativeNumIsInfinity(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "isInteger", imp: nativeNumIsInteger(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "isNan", imp: nativeNumIsNan(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "toString", imp: nativeNumToString(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "truncate", imp: nativeNumTruncate(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "==(_)", imp: nativeNumEqual(virtual:stack:argsStart:))
    virtual.numClass.bindNativeMethod(virtual: virtual, selector: "!=(_)", imp: nativeNumNotEqual(virtual:stack:argsStart:))
    
    
    guard let systemClassObject = getClassFromModule(module: coreModule, name: "System") else {
        fatalError()
    }
    virtual.systemClass = systemClassObject
    systemClassObject.header.cls?.bindNativeMethod(virtual: virtual, selector: "clock", imp: nativeSystemClock(virtual:stack:argsStart:))
    systemClassObject.header.cls?.bindNativeMethod(virtual: virtual, selector: "importModule(_)", imp: nativeSystemImportModule(virtual:stack:argsStart:))
    systemClassObject.header.cls?.bindNativeMethod(virtual: virtual, selector: "getModuleVariable(_,_)", imp: nativeSystemGetModuleVariable(virtual:stack:argsStart:))
    systemClassObject.header.cls?.bindNativeMethod(virtual: virtual, selector: "writeString_(_)", imp: nativeSystemWriteString(virtual:stack:argsStart:))
    
    
    
    guard let stringClassObject = getClassFromModule(module: coreModule, name: "String") else {
        fatalError()
    }
    virtual.stringClass = stringClassObject
    virtual.stringClass.bindNativeMethod(virtual: virtual, selector: "toString", imp: nativeStringToString(virtual:stack:argsStart:))
    
    guard let mapClassObject = getClassFromModule(module: coreModule, name: "Map") else {
        fatalError()
    }
    virtual.mapClass = mapClassObject

    guard let rangeClassObject = getClassFromModule(module: coreModule, name: "Range") else {
        fatalError()
    }
    virtual.rangeClass = rangeClassObject

    
    guard let listClassObject = getClassFromModule(module: coreModule, name: "List") else {
       fatalError()
    }
    virtual.listClass = listClassObject
    return
}

/// 获取一个模块
public func getModule(virtual: Virtual, name: String) -> ModuleObject? {
    return virtual.allModules[name]?.toModuleObject()
}


/// 获取核心模块
public func getCoreModule(virtual: Virtual) -> ModuleObject? {
    return getModule(virtual: virtual, name: ModuleName.core)
}


/// 加载一个模块
public func loadModule(virtual: Virtual, name: String, code: String)  -> ThreadObject? {
    guard let coreModule = getCoreModule(virtual: virtual) else {
        fatalError("core module is null")
    }
    
    var module = getModule(virtual: virtual, name: name)
    if module == nil {
        module = ModuleObject(name: name, virtual: virtual)
        virtual.allModules[name] = AnyValue(value: module)
        
        for i in 0..<coreModule.moduleVarNames.count {
            let name = coreModule.moduleVarNames[i]
            let value = coreModule.moduleVarValues[i]
            module!.defineModuleVar(virtual: virtual, name: name, value: value)
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
    PLDebugPrint("")
    PLDebugPrint("build module `\(module.name)` start")
    let lexParser = LexParser(virtual: virtual,
                              moduleName: module.name,
                              module: module,
                              file: module.name,
                              code: code)

    let moduleUnit = CompilerUnit(lexParser: lexParser, enclosingUnit: nil, isMethod: false)
    
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
    PLDebugPrint("build module `\(module.name)` end")
    return endCompile(unit: moduleUnit)
}

public func compileProgram(unit: CompilerUnit) {
    if unit.curLexParser.matchCurToken(expected: .class_) {
        compileClassDefinition(unit: unit)
        
    } else if unit.curLexParser.matchCurToken(expected: .func_) {
        compileFunctionDefinition(unit: unit)
        
    } else if unit.curLexParser.matchCurToken(expected: .var_) {
        let preToken = unit.curLexParser.preToken
        compileVarDefinition(unit: unit, isStatic: preToken.type == .static_)
        
    } else if unit.curLexParser.matchCurToken(expected: .import_) {
        compileImport(unit: unit)
        
    } else {
        compileStatment(unit: unit)
    }
}


public func getClassFromModule(module: ModuleObject, name: String) -> ClassObject? {
    guard let index = module.moduleVarNames.firstIndex(of: name) else {
        return nil
    }
    return module.moduleVarValues[index].toClassObject()
}

public func switchThread(virtual: Virtual, nextThread: ThreadObject, stack:inout [AnyValue], argsStart: Index, withArg: Bool) -> Bool {
    if nextThread.caller != nil {
        fatalError("thread has been called!")
    }
    nextThread.caller = virtual.thread
    if nextThread.usedFrameNum == 0 {
        //TODO: 需要增加ErrorObject类型
        virtual.thread?.errorObject = AnyValue(value: "a finished thread can`t be switched to!")
        return false
    }
    if nextThread.errorObject != nil {
        virtual.thread?.errorObject = AnyValue(value: "a aborted thread can`t be switched to!")
        return false
    }
    
    if withArg {
        virtual.thread?.esp -= 1
    }
    guard nextThread.esp > 0 else {
        fatalError("esp should be greater than stack!")
    }
    nextThread.stack[nextThread.esp - 1] = withArg ? stack[argsStart + 1] : AnyValue(value: nil)
    virtual.thread = nextThread
    return false
}


public func importModule(virtual: Virtual, moduleName: String) -> ThreadObject? {
    if virtual.allMethodNames.contains(moduleName) {
        return nil
    }
    
    let code = Loader.loadModule(name: moduleName)
    return loadModule(virtual: virtual, name: moduleName, code: code)
}

public func getModuleVariable(virtual: Virtual, moduleName: String, varName: String) -> AnyValue? {
    guard let moduleObject = getModule(virtual: virtual, name: moduleName) else {
        virtual.thread?.errorObject = AnyValue(value: "module \(moduleName) is not loaded")
        return nil
    }
    
    guard let index = moduleObject.moduleVarNames.firstIndex(of: moduleName) else {
        virtual.thread?.errorObject = AnyValue(value: "variable \(varName) is not in module \(moduleName)")
        return nil
    }
    return moduleObject.moduleVarValues[index]
}
