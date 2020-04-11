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
    virtual.objectClass = ClassObject.defineClass(virtual: virtual, module: coreModule, name: ClassNameObject)
    
    /// 绑定原生方法
//    bindNativeMethod(virtual: virtual, cls: virtual.objectClass, selector: "!", imp: nativeObjectEqual)
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "==(_)", imp: nativeObjectEqual(virtual:args:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "!=(_)", imp: nativeObjectNotEqual(virtual:args:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "is(_)", imp: nativeObjectIs(virtual:args:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "className(_)", imp: nativeObjectGetClassName(virtual:args:))
    virtual.objectClass.bindNativeMethod(virtual: virtual, selector: "class(_)", imp: nativeObjectGetClass(virtual:args:))
    
    /// 创建Class类
   
    virtual.classOfClass =  ClassObject.defineClass(virtual: virtual, module: coreModule, name: ClassNameClass)
    
    /// 绑定原生方法
    virtual.classOfClass.bindNativeMethod(virtual: virtual, selector: "name", imp: nativeClassGetName(virtual:args:))
    virtual.classOfClass.bindNativeMethod(virtual: virtual, selector: "superClass", imp: nativeClassGetSuperClass(virtual:args:))
    
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
    
}





