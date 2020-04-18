//
//  NativeFn.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/15.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

/// 取反
public func nativeObjectNot(virtual: Virtual, stack: inout [AnyValue], argsStart: Index) -> Bool {
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: false))
    return true
}

/// 原生方法: 判断Object是否相等
public func nativeObjectEqual(virtual: Virtual, stack: inout [AnyValue], argsStart: Index) -> Bool {
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: stack[argsStart] == stack[argsStart + 1]))
    return true
}

/// 原生方法: 判断Object是否不相等
public func nativeObjectNotEqual(virtual: Virtual, stack: inout [AnyValue], argsStart: Index) -> Bool {
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: !(stack[argsStart] == stack[argsStart + 1])))
    return true
}

/// 原生方法: 判断Object是否属于Class的实例(包括继承)
public func nativeObjectIs(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard stack[argsStart + 1].isClassObject() else {
        //TODO: 运行时错误
        return false
    }
    
    var thisCls: ClassObject? = stack[argsStart].getClass(virtual: virtual)
    let baseCls = stack[argsStart + 1].toClassObject()

    while thisCls != nil {
        if thisCls == baseCls {
            stack[argsStart] = AnyValue(value: true)
            return true
        }
        thisCls = thisCls?.superClass
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: false))
    return true
}

/// 原生方法: 获取Object的类名
public func nativeObjectGetClassName(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    let cls = stack[argsStart].getClass(virtual: virtual)
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: cls.name))
    return true
}

/// 原生方法: 获取Object所属的类
public func nativeObjectGetClass(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    let cls = stack[argsStart].getClass(virtual: virtual)
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: cls))
    return true
}

/// 原生方法: 获取Class的name
public func nativeClassGetName(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    let cls = stack[argsStart]
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: cls.getClass(virtual: virtual).name))
    return true
}

/// 原生方法: 获取Class的基类
public func nativeClassGetSuperClass(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    let cls = stack[argsStart]
    if let superCls = cls.toClassObject()?.superClass {
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: superCls))
    } else {
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: nil))
    }
    return true
}


/// 原生方法: 设置返回值
private func RET_VALUE(stack:inout [AnyValue], argsStart: Index, ret: AnyValue) {
    stack[argsStart] = ret
}

