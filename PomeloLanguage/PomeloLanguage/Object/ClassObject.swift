//
//  Class.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa



public class ClassObject: NSObject, ObjectProtocol {
    /// 指向metaClass
    public var header: Header
    
    /// 基类
    var superClass: ClassObject?
    
    /// 域的个数存储在类中
    var fieldNum: Int = 0
    /// key: 方法签名 value: 方法实现
    var methods: SymbolTable<Selector, Method>
    var name: String
    
    init(header: Header, superClass: ClassObject?, name: String) {
        self.header = header
        self.superClass = superClass
        self.name = name
        self.methods = [:]
    }
}

/// 创建一个裸类
public func createRawClass(virtual: Virtual, name: String, fieldNum: Int) -> ClassObject {
    /// 裸类没有所属类
    let rawClassHeader = Header(virtual: virtual, type: .class_, cls: nil)
    /// 裸类没有父类
    let rawClass = ClassObject(header: rawClassHeader, superClass: nil, name: name)
    return rawClass
}

public func defineClass(virtual: Virtual, module: ModuleObject, name: String) -> ClassObject {
    let cls = createRawClass(virtual: virtual, name: name, fieldNum: 0)
    try! defineModuleVar(virtual: virtual, module: module, name: name, value: Value(value: cls))
    return cls
}

public func bindMethod(virtual: Virtual, cls: ClassObject,selector: String, method: Method) {
    cls.methods[selector] = method
}

public func bindSuperClass(virtual: Virtual, cls: ClassObject, superCls: ClassObject) {
    cls.superClass = superCls
    
    /// 继承成员变量数
    cls.fieldNum += superCls.fieldNum
    
    /// 继承方法
    for (selector, method) in superCls.methods {
        bindMethod(virtual: virtual, cls: cls, selector: selector, method: method)
    }
}

public func bindMetaClass(virtual: Virtual, cls: ClassObject, metaCls: ClassObject) {
    cls.header.cls = metaCls
}

/// 绑定原生方法
public func bindNativeMethod(virtual: Virtual,cls: ClassObject, selector: String,  imp: @escaping Method.NativeFnObject) {
    let method = Method(nativeImp: imp)
    bindMethod(virtual: virtual, cls: cls, selector: selector, method: method)
}
