//
//  Core.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

/// 核心模块名
public let CoreModule = "Core"


// MARK: Module

public func buildCore(virtual: Virtual) {

    let coreModule = ModuleObject(name: CoreModule, virtual: virtual)
    virtual.allModules[CoreModule] = coreModule
    
    /// 创建Object类
    virtual.objectClass = defineClass(virtual: virtual, module: coreModule, name: "Object")
    
    /// 绑定原生方法
//    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "!", imp: nativeObjectEqual)
    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "==(_)", imp: nativeObjectEqual(virtual:args:))
    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "!=(_)", imp: nativeObjectNotEqual(virtual:args:))
    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "is(_)", imp: nativeObjectIs(virtual:args:))
    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "className(_)", imp: nativeObjectGetClassName(virtual:args:))
    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "class(_)", imp: nativeObjectGetClass(virtual:args:))
    
    /// 创建Class类
    virtual.classOfClass = defineClass(virtual: virtual, module: coreModule, name: "Class")
    
    /// 绑定原生方法
    bindNativeMethod(virtual: virtual, cls: virtual.classOfClass, selector: "name", imp: nativeClassGetName(virtual:args:))
    bindNativeMethod(virtual: virtual, cls: virtual.classOfClass, selector: "superClass", imp: nativeClassGetSuperClass(virtual:args:))
    
    /// 绑定基类
    bindSuperClass(virtual: virtual, cls: virtual.classOfClass, superCls: virtual.objectClass)
    
    /// 创建ObjectMeta类
    let objectMetaClass = defineClass(virtual: virtual, module: coreModule, name: "ObjectMeta")
    
    /// 绑定基类
    bindSuperClass(virtual: virtual, cls: objectMetaClass, superCls: virtual.classOfClass)
    
    /// 绑定meta类
    bindMetaClass(virtual: virtual, cls: virtual.objectClass, metaCls: objectMetaClass)
    
    bindMetaClass(virtual: virtual, cls: objectMetaClass, metaCls: virtual.classOfClass)
    
    bindMetaClass(virtual: virtual, cls: virtual.classOfClass, metaCls: virtual.classOfClass)
}


public func defineModuleVar(virtual: Virtual,module: ModuleObject, name: String, value: Value) throws {
    guard name.count <= maxIdLength else {
        throw BuildError.unknown
    }
    
    /// 如果被提前引用，这次是实际定义，就从提前引用表删除，下面会定义
    if module.undefinedIvarNames.contains(name) {
        module.undefinedIvarNames.remove(name)
    }
    
    /// 如果没定义过，就直接定义
    guard let _ = module.ivarTable[name] else {
        module.ivarTable[name] = value
        return
    }
    throw BuildError.unknown
}


/// 获取一个模块
/// - Parameters:
///   - virtual: 虚拟机
///   - name: 模块名
public func getModule(virtual: Virtual, name: String) -> ModuleObject? {
    return virtual.allModules[name]
}


/// 加载一个模块
/// - Parameters:
///   - virtual: 虚拟机
///   - name: 模块名
///   - code: 源码
public func loadModule(virtual: Virtual, name: String, code: String) -> ThreadObject? {
    var module = getModule(virtual: virtual, name: name)
    if module == nil {
        module = ModuleObject(name: name, virtual: virtual)
        if let module = module {
            virtual.allModules[name] = module
            if let coreModule = getModule(virtual: virtual, name: CoreModule){
                for (name,value) in coreModule.ivarTable {
                    try! defineModuleVar(virtual: virtual, module: module, name: name, value: value)
                }
            }
        }
    }
    if let module = module {
        let fnObj = compileModule(virtual: virtual, module: module, code: code)
        let closureObj = ClosureObject(virtual: virtual, fn: fnObj)
        return ThreadObject(virtual: virtual, closure: closureObj)
    }
    return nil
}

public func executeModule(virtual: Virtual, name: String, code: String) -> Virtual.result {
    let _ = loadModule(virtual: virtual, name: name, code: code)
    return .success
}


// MARK: Class




// MARK: PremMethod


