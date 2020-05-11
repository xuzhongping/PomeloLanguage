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

//MARK: Bool

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

//MARK: Thread

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
        virtual.thread?.errorObject = AnyValue(value: "argument must be a thread!")
        return false
    }
    return switchThread(virtual: virtual, nextThread: thread, stack: &stack, argsStart: argsStart, withArg: false)
}

/// 原生方法: threadObject.call(arg)
public func nativeThreadCallWithArg(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let thread = stack[argsStart].toThreadObject() else {
        virtual.thread?.errorObject = AnyValue(value: "argument must be a thread!")
        return false
    }
    return switchThread(virtual: virtual, nextThread: thread, stack: &stack, argsStart: argsStart, withArg: true)
}

/// 原生方法: thread.isDone 线程是否运行完成
public func nativeThreadIsDone(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let thread = stack[argsStart].toThreadObject() else {
        virtual.thread?.errorObject = AnyValue(value: "argument must be a thread!")
        return false
    }
    if thread.usedFrameNum == 0 || thread.errorObject != nil {
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: true))
    } else {
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: false))
    }
    return true
}

/// 原生方法: Fn.new(_) 新建一个函数对象
public func nativeFnNew(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let closureObject = stack[argsStart + 1].toClosureObject() else {
        virtual.thread?.errorObject = AnyValue(value: "argument must be a closure!")
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: closureObject))
    return true
}
//MARK: Null

/// 原生方法: null取非
public func nativeNullNot(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: true))
    return true
}

/// 原生方法: null的字符串化
public func nativeNullToString(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: "null"))
    return true
}

//MARK: Num

/// 原生方法: 将字符串转为数字
public func nativeNumFromString(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let string = stack[argsStart].toString() else {
        return false
    }
    guard let number = Double(string) else {
        virtual.thread?.errorObject = AnyValue(value: "argument must be a number!")
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: number))
    return true
}


/// 原生方法: 返回圆周率
public func nativeNumPi(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: Double.pi))
    return true
}

/// 原生方法: 加
public func nativeNumPlus(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: left + right))
    return true
}

/// 原生方法: 减
public func nativeNumMinus(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: left - right))
    return true
}


/// 原生方法: 乘
public func nativeNumMul(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: left * right))
    return true
}


/// 原生方法: 除
public func nativeNumDiv(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: left / right))
    return true
}


/// 原生方法: 大于
public func nativeNumGt(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: left > right))
    return true
}


/// 原生方法: 大于等于
public func nativeNumGe(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: left >= right))
    return true
}


/// 原生方法: 小于
public func nativeNumLt(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: left < right))
    return true
}


/// 原生方法: 小于等于
public func nativeNumLe(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: left <= right))
    return true
}

/// 原生方法: 位运算与
public func nativeNumBitAnd(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: Int(left) & Int(right)))
    return true
}

/// 原生方法: 位运算或
public func nativeNumBitOr(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: Int(left) | Int(right)))
    return true
}



/// 原生方法: 位运算左移
public func nativeNumBitShiftLeft(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: Int(left) << Int(right)))
    return true
}


/// 原生方法: 位运算右移
public func nativeNumBitShiftRight(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: Int(left) >> Int(right)))
    return true
}

/// 原生方法: 绝对值
public func nativeNumAbs(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: abs(value)))
    return true
}

/// 原生方法: acos
public func nativeNumAcos(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: acos(value)))
    return true
}


/// 原生方法: asin
public func nativeNumAsin(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: asin(value)))
    return true
}


/// 原生方法: atan
public func nativeNumAtan(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: atan(value)))
    return true
}


/// 原生方法: ceil
public func nativeNumCeil(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: ceil(value)))
    return true
}


/// 原生方法: cos
public func nativeNumCos(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: cos(value)))
    return true
}


/// 原生方法: floor
public func nativeNumFloor(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: floor(value)))
    return true
}


/// 原生方法: 负数
public func nativeNumNegate(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: -(value)))
    return true
}


/// 原生方法: sin
public func nativeNumSin(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: sin(value)))
    return true
}


/// 原生方法: sqrt
public func nativeNumSqrt(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: sqrt(value)))
    return true
}


/// 原生方法: tan
public func nativeNumTan(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: tan(value)))
    return true
}

/// 原生方法: 取模
public func nativeNumMod(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: fmod(left, right)))
    return true
}

/// 原生方法: 取反
public func nativeNumBitNot(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: ~uint(value)))
    return true
}

/// 原生方法: [from..to]
public func nativeNumRange(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: RangeObject(virtual: virtual, from: Int(left), to: Int(right))))
    return true
}


/// 原生方法: atan2
public func nativeNumAtan2(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: atan2(left, right)))
    return true
}


/// 原生方法: 返回小数部分
public func nativeNumFraction(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
//    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: modf(value, <#T##UnsafeMutablePointer<Double>!#>)))
    return true
}


/// 原生方法: 是否无穷大，不区分正负
public func nativeNumIsInfinity(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: value == Double.infinity))
    return true
}

/// 原生方法: 是否是数字
public func nativeNumIsInteger(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    if value.isNaN || value.isInfinite {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: trunc(value) == value ))
    return true
}

/// 原生方法: 是否为nan
public func nativeNumIsNan(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: value.isNaN))
    return true
}

/// 原生方法: 转换为字符串
public func nativeNumToString(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: String(value)))
    return true
}

/// 原生方法: 取整数部分
public func nativeNumTruncate(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNum() else {
        return false
    }
//    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: modf(<#T##Double#>, <#T##UnsafeMutablePointer<Double>!#>)))
    return true
}

/// 原生方法: 判断两个数字是否相等
public func nativeNumEqual(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: left == right))
    return true
}

/// 原生方法: 判断两个数字是否不相等
public func nativeNumNotEqual(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNum() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNum() else {
        return true
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: left != right))
    return true
}
