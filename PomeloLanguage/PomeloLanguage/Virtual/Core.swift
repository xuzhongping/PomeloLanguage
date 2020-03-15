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
    
    /// 创建Class类
    virtual.classOfClass = defineClass(virtual: virtual, module: coreModule, name: "Class")
    
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
        throw PomeloError.unknow
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
    throw PomeloError.unknow
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
/// 创建一个裸类
public func createRawClass(virtual: Virtual, name: String, fieldNum: Int) -> Class {
    /// 裸类没有所属类
    let rawClassHeader = Header(virtual: virtual, type: .class_, cls: nil)
    /// 裸类没有父类
    let rawClass = Class(header: rawClassHeader, superClass: nil, name: name)
    return rawClass
}

public func defineClass(virtual: Virtual, module: ModuleObject, name: String) -> Class {
    let cls = createRawClass(virtual: virtual, name: name, fieldNum: 0)
    try! defineModuleVar(virtual: virtual, module: module, name: name, value: Value(type: .obj, value: cls))
    return cls
}

public func bindMethod(virtual: Virtual, cls: Class,selector: String, method: Method) {
    cls.methods[selector] = method
}

public func bindSuperClass(virtual: Virtual, cls: Class, superCls: Class) {
    cls.superClass = superCls
    
    /// 继承成员变量数
    cls.fieldNum += superCls.fieldNum
    
    /// 继承方法
    for (selector, method) in superCls.methods {
        bindMethod(virtual: virtual, cls: cls, selector: selector, method: method)
    }
}

public func bindMetaClass(virtual: Virtual, cls: Class, metaCls: Class) {
    cls.header.cls = metaCls
}

// MARK: PremMethod

public func bindPrimMethod(fn: Any, methodName: String, cls: Class) {
    
}

private func primObjectEqual(virtual: Virtual, args: inout [Value]) {
//    let equal = args[0].value == args[1].value
    
}

