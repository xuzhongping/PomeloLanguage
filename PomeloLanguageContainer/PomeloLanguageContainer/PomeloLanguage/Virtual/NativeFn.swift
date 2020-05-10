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

/// 原生方法: 返回Bool值的字符串形式
public func nativeBoolToString(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toBool() else {
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: "false"))
        return true
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: value ? "true" : "false"))
    return true
}

/// 原生方法: Bool值取反
public func nativeBoolNot(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toBool() else {
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: true))
        return true
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: !value))
    return true
}

/// 原生方法: Thread.new(func): 创建一个thread实例
public func nativeThreadNew(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let closureObject = stack[argsStart + 1].toClosureObject() else {
        virtual.thread?.errorObject = AnyValue(value: "argument must be a function!")
        return false
    }
    
    let threadObject = ThreadObject(virtual: virtual, closure: closureObject)
    threadObject.stack[argsStart] = AnyValue(value: nil)
    threadObject.esp += 1
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: threadObject))
    return true
}

/// 原生方法: Thread.abort(err): 以错误信息err为参数退出线程
public func nativeThreadAbort(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    virtual.thread?.errorObject = AnyValue(value: stack[argsStart])
    return stack[argsStart + 1].isNull()
}

/// 原生方法: Thread.current: 返回当前线程对象
public func nativeThreadCurrent(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let thread = virtual.thread else {
        fatalError()
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: thread))
    return true
}

/// 原生方法: Thread.suspend(): 挂起当前线程，退出解析器
public func nativeThreadSuspend(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    virtual.thread = nil
    return false
}

/// 原生方法: Thread.yield(arg): 带参数让出CPU
public func nativeThreadYieldWithArg(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    let curThread = virtual.thread
    virtual.thread = curThread?.caller
    curThread?.caller = nil
    
    if let thread = virtual.thread {
        thread.stack[thread.esp - 1] = stack[argsStart + 1]
        curThread?.esp -= 1
    }
    return false
}

/// 原生方法: Thread.yield(): 不带参数让出CPU
public func nativeThreadYieldWithoutArg(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    let curThread = virtual.thread
    virtual.thread = curThread?.caller
    curThread?.caller = nil
    
    if let thread = virtual.thread {
        thread.stack[thread.esp - 1] = AnyValue(value: nil)
    }
    return false
}

/// 原生方法: threadObject.call()
public func nativeThreadCallWithoutArg(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let thread = stack[argsStart].toThreadObject() else {
        fatalError()
    }
    return switchThread(virtual: virtual, nextThread: thread, stack: &stack, argsStart: argsStart, withArg: false)
}

/// 原生方法: threadObject.call(arg)
public func nativeThreadCallWithArg(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let thread = stack[argsStart].toThreadObject() else {
        fatalError()
    }
    return switchThread(virtual: virtual, nextThread: thread, stack: &stack, argsStart: argsStart, withArg: true)
}

/// 原生方法: thread.isDone 线程是否运行完成
public func nativeThreadIsDone(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let thread = stack[argsStart].toThreadObject() else {
        fatalError()
    }
    if thread.usedFrameNum == 0 || thread.errorObject != nil {
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: true))
    } else {
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: false))
    }
    return true
}

public func nativeFnNew(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let closureObject = stack[argsStart + 1].toClosureObject() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: closureObject))
    return true
}

