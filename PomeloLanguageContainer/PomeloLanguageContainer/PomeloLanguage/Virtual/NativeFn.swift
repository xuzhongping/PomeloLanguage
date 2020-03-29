//
//  NativeFn.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/15.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

/// 原生方法: 判断Object是否相等
public func nativeObjectEqual(virtual: Virtual, args: inout [AnyValue]) -> Bool {
    RET_VALUE(args: &args, ret: AnyValue(value: args[0] == args[1]))
    return true
}

/// 原生方法: 判断Object是否不相等
public func nativeObjectNotEqual(virtual: Virtual, args: inout [AnyValue]) -> Bool {
    RET_VALUE(args: &args, ret: AnyValue(value: !(args[0] == args[1])))
    return true
}

/// 原生方法: 判断Object是否属于Class的实例(包括继承)
public func nativeObjectIs(virtual: Virtual, args: inout [AnyValue]) -> Bool {
    guard args[1].isClassObject() else {
        //TODO: 运行时错误
        return false
    }
    
    var thisCls: ClassObject? = args[0].getClass(virtual: virtual)
    let baseCls = args[1].toClassObject()

    while thisCls != nil {
        if thisCls == baseCls {
            args[0] = AnyValue(value: true)
            return true
        }
        thisCls = thisCls?.superClass
    }
    RET_VALUE(args: &args, ret: AnyValue(value: false))
    return true
}

/// 原生方法: 获取Object的类名
public func nativeObjectGetClassName(virtual: Virtual, args: inout [AnyValue]) -> Bool {
    let cls = args[0].getClass(virtual: virtual)
    RET_VALUE(args: &args, ret: AnyValue(value: cls.name))
    return true
}

/// 原生方法: 获取Object所属的类
public func nativeObjectGetClass(virtual: Virtual, args: inout [AnyValue]) -> Bool {
    let cls = args[0].getClass(virtual: virtual)
    RET_VALUE(args: &args, ret: AnyValue(value: cls))
    return true
}

/// 原生方法: 获取Class的name
public func nativeClassGetName(virtual: Virtual, args: inout [AnyValue]) -> Bool {
    let cls = args[0]
    RET_VALUE(args: &args, ret: AnyValue(value: cls.getClass(virtual: virtual).name))
    return true
}

/// 原生方法: 获取Class的基类
public func nativeClassGetSuperClass(virtual: Virtual, args: inout [AnyValue]) -> Bool {
    let cls = args[0]
    if let superCls = cls.toClassObject()?.superClass {
        RET_VALUE(args: &args, ret: AnyValue(value: superCls))
    } else {
        RET_VALUE(args: &args, ret: AnyValue(value: nil))
    }
    return true
}


/// 原生方法: 设置返回值
private func RET_VALUE(args: inout [AnyValue], ret: AnyValue) {
    args[0] = ret
}

