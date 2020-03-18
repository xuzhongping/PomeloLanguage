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
    virtual.allModules[ModuleNameCore] = coreModule
    
    /// 创建Object类
    virtual.objectClass = defineClass(virtual: virtual, module: coreModule, name: ClassNameObject)
    
    /// 绑定原生方法
//    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "!", imp: nativeObjectEqual)
    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "==(_)", imp: nativeObjectEqual(virtual:args:))
    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "!=(_)", imp: nativeObjectNotEqual(virtual:args:))
    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "is(_)", imp: nativeObjectIs(virtual:args:))
    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "className(_)", imp: nativeObjectGetClassName(virtual:args:))
    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "class(_)", imp: nativeObjectGetClass(virtual:args:))
    
    /// 创建Class类
    virtual.classOfClass = defineClass(virtual: virtual, module: coreModule, name: ClassNameClass)
    
    /// 绑定原生方法
    bindNativeMethod(virtual: virtual, cls: virtual.classOfClass, selector: "name", imp: nativeClassGetName(virtual:args:))
    bindNativeMethod(virtual: virtual, cls: virtual.classOfClass, selector: "superClass", imp: nativeClassGetSuperClass(virtual:args:))
    
    /// 绑定基类
    bindSuperClass(virtual: virtual, cls: virtual.classOfClass, superCls: virtual.objectClass)
    
    /// 创建ObjectMeta类
    let objectMetaClass = defineClass(virtual: virtual, module: coreModule, name: ClassNameObjectMeta)
    
    /// 绑定基类
    bindSuperClass(virtual: virtual, cls: objectMetaClass, superCls: virtual.classOfClass)
    
    /// 绑定meta类
    bindMetaClass(virtual: virtual, cls: virtual.objectClass, metaCls: objectMetaClass)
    
    bindMetaClass(virtual: virtual, cls: objectMetaClass, metaCls: virtual.classOfClass)
    
    bindMetaClass(virtual: virtual, cls: virtual.classOfClass, metaCls: virtual.classOfClass)
    
    executeModule(virtual: virtual, name: ModuleNameCore, code: "")
}





