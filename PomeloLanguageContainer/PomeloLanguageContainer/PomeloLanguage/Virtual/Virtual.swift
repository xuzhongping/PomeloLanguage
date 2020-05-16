//
//  Virtual.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/10.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public class Virtual: NSObject {
    
    public enum result {
        case success
        case error
    }
    
    var allocatedBytes: Int
    var lexParser: LexParser?
    var allObjectHeader: Header?
    
    /// 当前线程
    var thread: ThreadObject?
    
    /// Class类
    var classOfClass: ClassObject!
    
    /// Object类
    var objectClass: ClassObject!
    
    /// String类
    var stringClass: ClassObject!
    
    /// Map类
    var mapClass: ClassObject!
    
    /// Range类
    var rangeClass: ClassObject!
    
    /// List类
    var listClass: ClassObject!
    
    /// Null类
    var nullClass: ClassObject!
    
    /// Bool类
    var boolClass: ClassObject!
    
    /// Number类
    var numClass: ClassObject!
    
    /// Fn类
    var fnClass: ClassObject!
    
    /// Thread类
    var threadClass: ClassObject!
    
    /// Module类
    var moduleClass: ClassObject!
    
    var systemClass: ClassObject!
    
    
    /// 内建类
//    var builtinClasses: [String] {
//        return ["stringClass",
//                mapClass,
//                rangeClass,
//                listClass,
//                nullClass,
//                boolClass,
//                numClass,
//                fnClass,
//                threadClass,
//                moduleClass,
//                systemClass
//            ]
    var builtinClasses: [ClassName] {
        return [ClassName.string,
                ClassName.map,
                ClassName.range,
                ClassName.list,
                ClassName.null,
                ClassName.bool,
                ClassName.num,
                ClassName.fn,
                ClassName.thread,
                ClassName.module,
                ClassName.system
                ]
    }
    
    /// 所有模块
    public var allModules: [String: AnyValue]
    
    /// 所有类的方法名集合(已去重)
    public var allMethodNames: [String]
    
    
    override init() {
        allocatedBytes = 0
        lexParser = nil
        allObjectHeader = nil
        allModules = [:]
        allMethodNames = []
        super.init()
//        buildCore(virtual: self)
    }
    
    /// 为closure在thread中创建运行时栈
    public func createFrame(thread: ThreadObject, closure: ClosureObject, argNum: Int) {
        thread.prepareFrame(closure: closure, stackIndex: thread.esp - argNum)
    }
    
    /// 关闭栈中lastIndex以上的upvalue
    public func closedUpvalue(thread: ThreadObject, lastIndex: Int) {
 
        for i in lastIndex..<thread.openUpvalues.count {
            let upvalue = thread.openUpvalues[i]
            if let localVarIndex = upvalue.localVarIndex {
                upvalue.closedUpvalue = thread.stack[localVarIndex]
//                upvalue.localVarIndex = up
            }
        }
    }
    
    /// 将localVar所属的upvalue插入openUpvalues中
    public func createOpenUpvalue(thread: ThreadObject, localVarIndex: Index) {
        let upvalue = UpvalueObject(virtual: self)
        upvalue.localVarIndex = localVarIndex
        thread.openUpvalues.append(upvalue)
    }
    
    /// 校验基类合法性
    public func validateSuperClass(name: String, superClass: ClassObject, fieldNum: Int)  {
        if builtinClasses.contains(superClass.name) {
            fatalError("superClass mustn`t be a buildin class!")
        }
        if superClass.fieldNum + fieldNum > maxFieldNum {
            fatalError("number of field including super exceed \(maxFieldNum)!")
        }
    }
    
    /// 执行指令
    public func executeInstruction(thread: ThreadObject) -> Virtual.result {
        var curThread = thread
        self.thread = thread
        
        var curFrame: CallFrame?
        var stackStartIndex: Index?
        var ip: Index = 0
        var fn: FnObject?
        var opCode: OP_CODE?
        
        func push(value: AnyValue) {
            curThread.stack.append(value)
            curThread.esp += 1
        }
        
        func pop() -> AnyValue? {
            let value = curThread.stack.last
            curThread.stack.removeLast()
            curThread.esp -= 1
            return value
        }
        
        func drop() {
            curThread.stack.removeLast()
            curThread.esp -= 1
        }
        
        func peek() -> AnyValue? {
            return curThread.stack[curThread.esp - 1]
        }
        
        func peek2() -> AnyValue? {
            return curThread.stack[curThread.esp - 2]
        }
        
        func setPeek(value: AnyValue) {
            curThread.stack[curThread.esp - 1] = value
        }
        
        func setPeek2(value: AnyValue) {
            curThread.stack[curThread.esp - 2] = value
        }
        
        func readByte() -> Byte? {
            guard let byte = fn?.byteStream[ip] else {
                fatalError()
            }
            ip += 1
            return byte
        }
        
        func readShort() -> Int? {
            guard let fn = fn else {
                fatalError()
            }
            ip += 2
            return Int(fn.byteStream[ip - 2]) << 8 | Int(fn.byteStream[ip - 1])
        }
        
        func storeFrame() {
            curFrame?.ip = ip
        }
        
        
        func loadFrame() {
            curFrame = curThread.frames.last
            guard let curFrame = curFrame else {
                fatalError()
            }
            stackStartIndex = curFrame.stackStart
            ip = curFrame.ip
            fn = curFrame.closure.fn
        }
        
        func decode() {
            guard let byte = readByte() else {
                fatalError()
            }
            opCode = OP_CODE(rawValue: byte)
        }
        
        func invokeMethod(index: Index, cls: ClassObject, argsNum: Int) -> Virtual.result? {
            if index > cls.methods.count {
                fatalError()
            }
            let method = cls.methods[index]
            switch method.type {
            case .none:
                fatalError()
            case .native:
                guard let imp = method.nativeImp else {
                    fatalError()
                }
                if imp(self, &curThread.stack, index) {
                    curThread.esp -= argsNum - 1 // -1 防止回收args[0]返回值
                } else {
                    storeFrame()
                    if self.thread == nil {
                        return .success
                    }
                    curThread = self.thread!
                    loadFrame()
                    
                    if let errObject = curThread.errorObject {
                        print(errObject)
                        setPeek(value: errObject)
                    }
                    if self.thread == nil {
                        return .success
                    }
                    
                    curThread = self.thread!
                    loadFrame()
                }
            case .script:
                storeFrame()
                guard let closureObject = method.scriptImp else {
                    fatalError()
                }
                createFrame(thread: curThread, closure: closureObject, argNum: argsNum)
                
                loadFrame()
            case .call:
                guard let closureObject = curThread.stack[thread.esp - argsNum].toClosureObject() else {
                    fatalError()
                }

                if argsNum - 1 < closureObject.fn.argNum {
                    fatalError("arguments less")
                }
                storeFrame()
  
                createFrame(thread: curThread, closure: closureObject, argNum: argsNum)
                
                loadFrame()
            }
            return nil
        }
        
        loadFrame()
        
        while true {
            decode()
            
            guard let opCode = opCode else {
                fatalError()
            }
            
            switch opCode {
            case .LOAD_LOCAL_VAR:
                guard let byte = readByte() else {
                    fatalError()
                }
                guard let stackStartIndex = stackStartIndex else {
                    fatalError()
                }
                push(value: curThread.stack[stackStartIndex + Int(byte)])
                
            case .LOAD_THIS_FIELD:
                guard let fieldIndex = readByte() else {
                    fatalError()
                }
                guard let stackStackIndex = stackStartIndex else {
                    fatalError()
                }
                guard let instanceObject = curThread.stack[stackStackIndex].toInstanceObject() else {
                    fatalError("method receiver should be instanceObj")
                }
                
                guard fieldIndex < (instanceObject.header.cls?.fieldNum ?? 0) else {
                    fatalError("out of bounds field!")
                }
                
                push(value: instanceObject.fields[Int(fieldIndex)])
                
            case .POP:
                drop()
            case .PUSH_NULL:
                push(value: AnyValue(value: nil))
            case .PUSH_FALSE:
                push(value: AnyValue(value: false))
            case .PUSH_TRUE:
                push(value: AnyValue(value: true))
            case .STORE_LOCAL_VAR:
                guard let byte = readByte() else {
                    fatalError()
                }
                guard let stackStackIndex = stackStartIndex else {
                    fatalError()
                }
                
                guard let value = peek() else {
                    fatalError("method receiver should be instanceObj")
                }
                
                curThread.stack[stackStackIndex + Int(byte)] = value
            case .LOAD_CONSTANT:
                guard let value = readShort() else {
                    fatalError()
                }
                guard let fn = fn else {
                    fatalError()
                }
                push(value: fn.constants[value])
            
            case .CALL0,
                 .CALL1,
                 .CALL2,
                 .CALL3,
                 .CALL4,
                 .CALL5,
                 .CALL6,
                 .CALL7,
                 .CALL8,
                 .CALL9,
                 .CALL10,
                 .CALL11,
                 .CALL12,
                 .CALL13,
                 .CALL14,
                 .CALL15,
                 .CALL16:
                
                guard let index = readShort() else {
                    fatalError()
                }
                
                let argNum = opCode.rawValue - OP_CODE.CALL0.rawValue + 1
            
                let argsIndex = curThread.esp - Int(argNum)
                
                let classObject = curThread.stack[argsIndex].getClass(virtual: self)
                
                if let result = invokeMethod(index: index, cls: classObject, argsNum: Int(argNum)) {
                    return result
                }
            case .SUPER0,
                 .SUPER1,
                 .SUPER2,
                 .SUPER3,
                 .SUPER4,
                 .SUPER5,
                 .SUPER6,
                 .SUPER7,
                 .SUPER8,
                 .SUPER9,
                 .SUPER10,
                 .SUPER11,
                 .SUPER12,
                 .SUPER13,
                 .SUPER14,
                 .SUPER15,
                 .SUPER16:
                
                guard let index = readShort() else {
                    fatalError()
                }
                
                let argNum = opCode.rawValue - OP_CODE.SUPER0.rawValue + 1
                
                guard let constIndex = readShort() else {
                    fatalError()
                }
                guard let classObject = fn?.constants[constIndex].toClassObject() else {
                    fatalError()
                }
                
                if let result = invokeMethod(index: index, cls: classObject, argsNum: Int(argNum)) {
                    return result
                }
                
            case .LOAD_UPVALUE:
                guard let value = readByte() else {
                    fatalError()
                }
                guard let upvalue = curFrame?.closure.upvalues[Int(value)].closedUpvalue else {
                    fatalError()
                }
                push(value: upvalue)
                
            case .STORE_UPVALUE:
                guard let value = peek() else {
                    fatalError()
                }
                guard let upvalueIndex = readByte() else {
                    fatalError()
                }
                curFrame?.closure.upvalues[Int(upvalueIndex)].closedUpvalue = value
                
            case .LOAD_MODULE_VAR:
                guard let index = readShort() else {
                    fatalError()
                }
                guard let fn = fn else {
                    fatalError()
                }
                push(value: fn.module.moduleVarValues[index])
                
            case .STORE_MODULE_VAR:
                guard let fn = fn else {
                    fatalError()
                }
                guard let index = readShort() else {
                    fatalError()
                }
                guard let value = peek() else {
                    fatalError()
                }
                fn.module.moduleVarValues[index] = value
                
            case .STORE_THIS_FIELD:
                guard let fieldIndex = readByte() else {
                    fatalError()
                }
                guard let stackStackIndex = stackStartIndex else {
                    fatalError()
                }
                guard let instance = curThread.stack[stackStackIndex].toInstanceObject() else {
                    fatalError("receiver should be instance!")
                }
                guard fieldIndex < instance.header.cls?.fieldNum ?? 0 else {
                    fatalError("out of bounds field!")
                }
                guard let top = peek() else {
                    fatalError()
                }
                instance.fields[Int(fieldIndex)] = top
                
            case .LOAD_FIELD:
                guard let fieldIndex = readByte() else {
                    fatalError()
                }
                guard let instance = pop()?.toInstanceObject() else {
                    fatalError("receiver should be instance!")
                }
                guard fieldIndex > instance.header.cls?.fieldNum ?? 0 else {
                    fatalError("out of bounds field!")
                }
                push(value: instance.fields[Int(fieldIndex)])
                
            case .STORE_FIELD:
                guard let fieldIndex = readByte() else {
                    fatalError()
                }
                guard let instance = pop()?.toInstanceObject() else {
                    fatalError("receiver should be instance!")
                }
                guard fieldIndex > instance.header.cls?.fieldNum ?? 0 else {
                    fatalError("out of bounds field!")
                }
                guard let top = peek() else {
                    fatalError()
                }
                instance.fields[Int(fieldIndex)] = top
                
            case .JUMP:
                guard let offset = readShort(), offset > 0 else {
                    fatalError("OPCODE_JUMP`s operand must be positive!")
                }
                ip += offset
                
            case .LOOP:
                guard let offset = readShort(), offset > 0 else {
                    fatalError("OPCODE_LOOP`s operand must be positive!")
                }
                ip -= offset
            case .JUMP_IF_FALSE:
                guard let offset = readShort(), offset > 0 else {
                    fatalError("OPCODE_JUMP_IF_FALSE`s operand must be positive!")
                }
                guard let condition = pop() else {
                    fatalError()
                }
                // 为null或为false时才为假，不包含0
                if condition.isNull() || condition.toBoolObject()?.value == false {
                    ip += offset
                }
                
            case .AND:
                guard let offset = readShort(), offset > 0 else {
                    fatalError("OPCODE_AND`s operand must be positive!")
                }
                guard let condition = peek() else {
                    fatalError()
                }
                if condition.isNull() || condition.toBoolObject()?.value == false {
                    ip += offset
                } else {
                    drop()
                }
                
            case .OR:
                guard let offset = readShort(), offset > 0 else {
                    fatalError("OPCODE_AND`s operand must be positive!")
                }
                guard let condition = peek() else {
                    fatalError()
                }
                if condition.isNull() || condition.toBoolObject()?.value == false {
                    drop()
                } else {
                    ip += offset
                }
                
            case .CLOSE_UPVALUE:
                closedUpvalue(thread: curThread, lastIndex: curThread.esp - 1)
                drop()
                
            case .RETURN:
                guard let retValue = pop() else {
                    fatalError()
                }
                curThread.frames.removeLast()
                guard let stackStartIndex = stackStartIndex else {
                    fatalError()
                }
                closedUpvalue(thread: curThread, lastIndex: stackStartIndex)
                if curThread.usedFrameNum == 0 {
                    guard let callerThread = curThread.caller else {
                        if curThread.stack.count == stackStartIndex {
                            curThread.stack.append(retValue)
                        } else {
                            curThread.stack[stackStartIndex] = retValue
                        }
                        curThread.esp = stackStartIndex + 1
                        return .success
                    }
                    curThread.caller = nil
                    curThread = callerThread
                    self.thread = callerThread
                    curThread.stack[curThread.esp - 1] = retValue
                } else {
                    curThread.stack[stackStartIndex] = retValue
                    curThread.esp = stackStartIndex + 1
                }
                
                loadFrame()
                
            case .CONSTRUCT:
                guard let stackStartIndex = stackStartIndex else {
                    fatalError()
                }
                guard let clsObject = curThread.stack[stackStartIndex].toClassObject() else {
                    fatalError("stack[0] should be a class for OPCODE_CONSTRUCT!")
                }
                
                let instance = InstanceObject(cls: clsObject, virtual: self)

                curThread.stack[stackStartIndex] = AnyValue(value: instance)
                
            case .CREATE_CLOSURE:
                guard let fnIndex = readShort() else {
                    fatalError()
                }
                guard let fnObject = fn?.constants[fnIndex].toFnObject() else {
                    fatalError()
                }
                
                guard let stackStartIndex = stackStartIndex else {
                    fatalError()
                }
                
                guard let curFrame = curFrame else {
                    fatalError()
                }
                
                let closureObject = ClosureObject(virtual: self, fn: fnObject)
                push(value: AnyValue(value: closureObject))
                
                for _ in 0..<fnObject.upvalueNum {
                    guard let isEnclosingLocalVar = readByte() else {
                        fatalError()
                    }
                    guard let index = readByte() else {
                        fatalError()
                    }
                    if isEnclosingLocalVar == 1 {
                        let upvalueObject = UpvalueObject(virtual: self)
                        upvalueObject.localVarIndex = stackStartIndex + Int(index)
                        closureObject.upvalues.append(upvalueObject)
                    } else {
                        closureObject.upvalues.append(curFrame.closure.upvalues[Int(index)])
                    }
                }
            
            case .CREATE_CLASS:
                
                // 指令流: 1字节的field数量
                // 栈顶: 基类 次栈顶: 子类名
                
                guard let filedNum = readByte() else {
                    fatalError()
                }
                
                guard let superClass = curThread.stack[curThread.esp - 1].toClassObject() else {
                    fatalError()
                }
                guard let className = curThread.stack[curThread.esp - 2].toStringObject()?.value else {
                    fatalError()
                }
                
                guard let stackStartIndex = stackStartIndex else {
                    fatalError()
                }
                
                drop()
                
                validateSuperClass(name: className, superClass: superClass, fieldNum: Int(filedNum))
                let classObject = ClassObject(virtual: self, name: className, fieldNum: Int(filedNum), superClass: superClass)
                thread.stack[stackStartIndex] = AnyValue(value: classObject)
                print("CREATE_CLASS_\(className)")
            case .INSTANCE_METHOD,
                 .STATIC_METHOD:
                
                // 指令类: 待绑定的方法名在vm->allMethodNames中的2字节的索引
                // 栈顶: 待绑定的类 次栈顶: 待绑定的方法
                guard let methodNameIndex = readShort() else {
                    fatalError()
                }
                guard let classObject = pop()?.toClassObject() else {
                    fatalError()
                }
                
                guard let methodObject = pop()?.toClosureObject() else {
                    fatalError()
                }
                
                bindMethodAndPatch(virtual: self, opCode: opCode, methodIndex: methodNameIndex, cls: classObject, method: methodObject)
            
            case .END:
                return .success
            }
        }
    }

}



/// 修正部分指令操作数
public func patchOperand(cls: ClassObject, fn: FnObject) {
    var ip = 0
    while true {
        guard let opCode = OP_CODE(rawValue: fn.byteStream[ip]) else {
            fatalError()
        }
        ip += 1
        switch opCode {
        case .LOAD_FIELD,
             .STORE_FIELD,
             .LOAD_THIS_FIELD,
             .STORE_THIS_FIELD:
            fn.byteStream[ip] += Byte(cls.superClass?.fieldNum ?? 0)
            ip += 1
        case .SUPER0,
             .SUPER1,
             .SUPER2,
             .SUPER3,
             .SUPER4,
             .SUPER5,
             .SUPER6,
             .SUPER7,
             .SUPER8,
             .SUPER9,
             .SUPER10,
             .SUPER11,
             .SUPER12,
             .SUPER13,
             .SUPER14,
             .SUPER15,
             .SUPER16:
            ip += 2
            let superClassIndex = Int(fn.byteStream[ip]) << 8 | Int(fn.byteStream[ip + 1])
            fn.constants[superClassIndex] = AnyValue(value: cls.superClass)
            ip += 2
        case .CREATE_CLOSURE:
            let fnIndex = Int(fn.byteStream[ip]) << 8 | Int(fn.byteStream[ip + 1])
            guard let fnObject = fn.constants[fnIndex].toFnObject() else {
                fatalError()
            }
            patchOperand(cls: cls, fn: fnObject)
            ip += getBytesOfByteCode(byteStream: fn.byteStream, constants: fn.constants, ip: ip - 1)
        case .END:
            return
        default:
            ip += getBytesOfByteCode(byteStream: fn.byteStream, constants: fn.constants, ip: ip - 1)
        }
    }
}

/// 绑定方法或修正操作数
public func bindMethodAndPatch(virtual: Virtual, opCode: OP_CODE, methodIndex: Index, cls: ClassObject, method: ClosureObject) {
    var tempClass = cls
    if opCode == .STATIC_METHOD {
        guard let metaClass = cls.header.cls else {
            fatalError()
        }
        tempClass = metaClass
    }

    let method = Method(scriptImp: method)
    
    patchOperand(cls: tempClass, fn: method.scriptImp!.fn)
    
    tempClass.bindMethod(virtual: virtual, index: methodIndex, method: method)
}
