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
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: false))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 判断Object是否相等
public func nativeObjectEqual(virtual: Virtual, stack: inout [AnyValue], argsStart: Index) -> Bool {
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: stack[argsStart] == stack[argsStart + 1]))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 判断Object是否不相等
public func nativeObjectNotEqual(virtual: Virtual, stack: inout [AnyValue], argsStart: Index) -> Bool {
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: !(stack[argsStart] == stack[argsStart + 1])))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
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
            stack[argsStart] = AnyValue(value: BoolObject(virtual: virtual, value: true))
            return true
        }
        thisCls = thisCls?.superClass
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: BoolObject(virtual: virtual, value: false)))
    return true
}

/// 原生方法: 获取Object的类名
public func nativeObjectGetClassName(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    let cls = stack[argsStart].getClass(virtual: virtual)
    let retValue = AnyValue(value: StringObject(virtual: virtual, value: cls.name))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
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
    let retValue = AnyValue(value: StringObject(virtual: virtual, value: cls.getClass(virtual: virtual).name))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
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
    guard let value = stack[argsStart].toBoolObject() else {
        let retValue = AnyValue(value: StringObject(virtual: virtual, value: "false"))
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
        return true
    }
    let retValue = AnyValue(value: StringObject(virtual: virtual, value: value.value ? "true" : "false"))
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: Bool值取反
public func nativeBoolNot(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toBoolObject() else {
        let retValue = AnyValue(value: BoolObject(virtual: virtual, value: true))
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
        return true
    }
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: !value.value))
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: retValue))
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
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: BoolObject(virtual: virtual, value: true)))
    } else {
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: BoolObject(virtual: virtual, value: false)))
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
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: BoolObject(virtual: virtual, value: true)))
    return true
}

/// 原生方法: null的字符串化
public func nativeNullToString(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: StringObject(virtual: virtual, value: "null")))
    return true
}

//MARK: Num

/// 原生方法: 将字符串转为数字
public func nativeNumFromString(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let string = stack[argsStart].toStringObject() else {
        return false
    }
    guard let number = Double(string.value) else {
        virtual.thread?.errorObject = AnyValue(value: "argument must be a number!")
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: number))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: retValue))
    return true
}


/// 原生方法: 返回圆周率
public func nativeNumPi(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: NumObject(virtual: virtual, value: Double.pi)))
    return true
}

/// 原生方法: 加
public func nativeNumPlus(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: left.value + right.value))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 减
public func nativeNumMinus(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: left.value - right.value))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: 乘
public func nativeNumMul(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: left.value * right.value))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: 除
public func nativeNumDiv(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: left.value / right.value))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: 大于
public func nativeNumGt(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: left.value > right.value))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: 大于等于
public func nativeNumGe(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: left.value >= right.value))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: 小于
public func nativeNumLt(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: left.value < right.value))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: 小于等于
public func nativeNumLe(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: left.value <= right.value))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 位运算与
public func nativeNumBitAnd(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: Double(Int64(left.value) & Int64(right.value))))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 位运算或
public func nativeNumBitOr(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: Double(Int64(left.value) | Int64(right.value))))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}



/// 原生方法: 位运算左移
public func nativeNumBitShiftLeft(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: Double(Int64(left.value) << Int64(right.value))))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: 位运算右移
public func nativeNumBitShiftRight(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: Double(Int64(left.value) >> Int64(right.value))))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 绝对值
public func nativeNumAbs(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: abs(value.value)))
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: acos
public func nativeNumAcos(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: acos(value.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: asin
public func nativeNumAsin(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: asin(value.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: atan
public func nativeNumAtan(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: atan(value.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: ceil
public func nativeNumCeil(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: ceil(value.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: cos
public func nativeNumCos(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: cos(value.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: floor
public func nativeNumFloor(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: floor(value.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: 负数
public func nativeNumNegate(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: -(value.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: sin
public func nativeNumSin(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: sin(value.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: sqrt
public func nativeNumSqrt(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: sqrt(value.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: tan
public func nativeNumTan(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: tan(value.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 取模
public func nativeNumMod(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: fmod(left.value, right.value)))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 取反
public func nativeNumBitNot(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: Double(~uint(value.value))))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: [from..to]
public func nativeNumRange(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: RangeObject(virtual: virtual, value: NSRange(location: Int(left.value), length: Int(right.value - left.value))))
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: atan2
public func nativeNumAtan2(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: atan2(left.value, right.value)))
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


/// 原生方法: 返回小数部分
public func nativeNumFraction(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
//    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: modf(value, <#T##UnsafeMutablePointer<Double>!#>)))
    return true
}


/// 原生方法: 是否无穷大，不区分正负
public func nativeNumIsInfinity(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: value.value == Double.infinity))
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 是否是数字
public func nativeNumIsInteger(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    if value.value.isNaN || value.value.isInfinite {
        return false
    }
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: trunc(value.value) == value.value))
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 是否为nan
public func nativeNumIsNan(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: value.value.isNaN))
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 转换为字符串
public func nativeNumToString(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: StringObject(virtual: virtual, value: String(value.value)))
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 取整数部分
public func nativeNumTruncate(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let value = stack[argsStart].toNumObject() else {
        return false
    }
//    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: modf(<#T##Double#>, <#T##UnsafeMutablePointer<Double>!#>)))
    return true
}

/// 原生方法: 判断两个数字是否相等
public func nativeNumEqual(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return false
    }
    let retValue = AnyValue(value: BoolObject(virtual: virtual, value: left.value == right.value))
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}

/// 原生方法: 判断两个数字是否不相等
public func nativeNumNotEqual(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let left = stack[argsStart].toNumObject() else {
        return false
    }
    guard let right = stack[argsStart + 1].toNumObject() else {
        return true
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: BoolObject(virtual: virtual, value: left.value != right.value)))
    return true
}

//MARK: List

/// 原生方法: ListObject.new() 创建一个新的list
public func nativeListNew(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: ListObject(virtual: virtual)))
    return true
}

public func nativeListSubscript(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let listObject = stack[argsStart].toListObject() else {
        virtual.thread?.errorObject = AnyValue(value: "caller must be a list instance!")
        return false
    }
    if let num = stack[argsStart + 1].toNumObject() {
        guard Int(num.value) < listObject.value.count else {
            return false
        }
        RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: listObject.value[Int(num.value)]))
        return true
    }
    
    guard let rangeObject = stack[argsStart + 1].toRangeObject() else {
        virtual.thread?.errorObject = AnyValue(value: "subscript should be integer or range!")
        return false
    }
    
    let newListObject = ListObject(virtual: virtual)
    for index in rangeObject.value.location..<rangeObject.value.length + rangeObject.value.location  {
        newListObject.value.append(listObject.value[index])
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: newListObject))
    return true
}


public func nativeListSubsciptSetter(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let listObject = stack[argsStart].toListObject() else {
        virtual.thread?.errorObject = AnyValue(value: "caller must be a list instance!")
        return false
    }
    
    guard let num = stack[argsStart + 1].toNumObject() else {
        return false
    }
    guard Int(num.value) < listObject.value.count else {
        return false
    }
    
    listObject.value[Int(num.value)] = stack[argsStart + 2]
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: stack[argsStart + 2])
    return true
}

public func nativeListAdd(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    return false
}

//MARK: System
public func nativeSystemClock(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    let retValue = AnyValue(value: NumObject(virtual: virtual, value: Date.timeIntervalSinceReferenceDate))
    
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: retValue)
    return true
}


public func nativeSystemImportModule(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let name = stack[argsStart + 1].toStringObject() else {
        return false
    }
    guard let nextThread = importModule(virtual: virtual, moduleName: name.value) else {
        return false
    }
    
    if virtual.thread?.errorObject != nil {
        return false
    }
    
    virtual.thread?.esp -= 1
    
    nextThread.caller = virtual.thread
    virtual.thread = nextThread
    return false
}


public func nativeSystemGetModuleVariable(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let moduleName = stack[argsStart + 1].toStringObject() else {
        return false
    }
    guard let variableName = stack[argsStart + 2].toStringObject() else {
        return false
    }
    guard let variable = getModuleVariable(virtual: virtual, moduleName: moduleName.value, varName: variableName.value) else {
        return false
    }
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: AnyValue(value: variable))
    return true
}

public func nativeSystemWriteString(virtual: Virtual, stack:inout [AnyValue], argsStart: Index) -> Bool {
    guard let string = stack[argsStart + 1].toStringObject() else {
        return false
    }
    if string.value.count == 0 {
        fatalError("string isn`t terminated!")
    }
    print(string)
    RET_VALUE(stack: &stack, argsStart: argsStart, ret: stack[argsStart + 1])
    return true
}
