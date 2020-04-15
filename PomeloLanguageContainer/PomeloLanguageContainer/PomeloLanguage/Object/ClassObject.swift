//
//  Class.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa



public class ClassObject: BaseObject {
    /// 基类
    var superClass: ClassObject?
    
    /// 域的个数存储在类中
    var fieldNum: Int = 0
    /// key: 方法签名 value: 方法实现
    var methods: [Method]
    var name: String
    
    init(virtual: Virtual, header: Header, superClass: ClassObject?, name: String) {
        self.superClass = superClass
        self.name = name
        self.methods = []
        super.init(virtual: virtual, type: header.type, cls: header.cls)
    }
    
    /// 创建一个裸类
    convenience init(rawClass virtual: Virtual, name: String, fieldNum: Int) {
        /// 裸类没有所属类
        let rawClassHeader = Header(virtual: virtual, type: .class_, cls: nil)
        self.init(virtual: virtual, header: rawClassHeader, superClass: nil, name: name)
    }
    
    /// 创建一个类
    convenience init(virtual: Virtual, name: String, fieldNum: Int, superClass: ClassObject) {
        // 先创建类的meta类
        let metaClass = ClassObject(rawClass: virtual, name: name, fieldNum: 0)
        metaClass.header.cls = virtual.classOfClass
        
        // 绑定classOfClass为meta类的基类
        metaClass.bindSuperClass(virtual: virtual, superClass: virtual.classOfClass)
        
        // 创建类
        self.init(rawClass: virtual, name: name, fieldNum: fieldNum)
        header.cls = metaClass
        bindSuperClass(virtual: virtual, superClass: superClass)
    }
    
    public static func defineClass(virtual: Virtual, module: ModuleObject, name: String) -> ClassObject {
        let cls = ClassObject(rawClass: virtual, name: name, fieldNum: 0)
        module.defineVar(virtual: virtual, name: name, value: AnyValue(value: cls))
        return cls
    }
    
    public func bindMethod(virtual: Virtual, selector: String, method: Method) {
        methods[selector] = method
    }
    
    /// 绑定原生方法
    public func bindNativeMethod(virtual: Virtual, selector: String,  imp: @escaping Method.NativeFnObject) {
        let method = Method(nativeImp: imp)
        bindMethod(virtual: virtual, selector: selector, method: method)
    }

    
    public func bindSuperClass(virtual: Virtual, superClass: ClassObject) {
        self.superClass = superClass
        /// 继承成员变量数
        self.fieldNum += superClass.fieldNum
        
        /// 继承方法
        for (selector, method) in superClass.methods {
            bindMethod(virtual: virtual, selector: selector, method: method)
        }
    }
    
    public func bindMetaClass(virtual: Virtual, metaClass: ClassObject) {
        header.cls = metaClass
    }
}

