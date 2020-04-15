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
    
    /// 当前栈帧
    var frame: CallFrame?
    
    /// 当前栈起始地址
    var stackStart: Index
    
    /// 当前ip
    var ip: Index
    
    /// 当前fn
    var fn: FnObject?
    
    var opCode: OP_CODE?
    
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
    
    /// Num类
    var numClass: ClassObject!
    
    /// Fn类
    var fnClass: ClassObject!
    
    /// Thread类
    var threadClass: ClassObject!
    
    /// 内建类
    var builtinClasses: [ClassObject] {
        [stringClass,
         mapClass,
         rangeClass,
         listClass,
         nullClass,
         boolClass,
         numClass,
         fnClass,
         threadClass
        ]
    }
    
    /// 所有模块
    public var allModules: [String: ModuleObject]
    
    /// 所有类的方法名集合(去重)
    public var allMethodNames: [String]
    override init() {
        allocatedBytes = 0
        lexParser = nil
        allObjectHeader = nil
        allModules = [:]
        allMethodNames = []
        
        stackStart = 0
        ip = 0
    }
    
    public static func create() -> Virtual {
        let virtual = Virtual()
        buildCore(virtual: virtual)
        return virtual
    }
    
    /// 为closure在thread中创建运行时栈
    public func createFrame(thread: ThreadObject, closure: ClosureObject, argNum: Int) {
        thread.prepareFrame(closure: closure, stackIndex: thread.esp - argNum)
    }
    
    /// 关闭栈中lastIndex以上的upvalue
    public func closedUpvalue(thread: ThreadObject, lastIndex: Int) {
        for i in lastIndex..<thread.openUpvalues.count {
            let upvalue = thread.openUpvalues[i]
            upvalue.closedUpvalue = upvalue.localVar
        }
    }
    
    /// 将localVar所属的upvalue插入openUpvalues中
    public func createOpenUpvalue(thread: ThreadObject, localVar: AnyValue) {
        let upvalue = UpvalueObject(virtual: self)
        thread.openUpvalues.append(upvalue)
    }
    
    /// 校验基类合法性
    public func validateSuperClass(name: String, superClass: ClassObject, fieldNum: Int)  {
        if builtinClasses.contains(superClass) {
            fatalError()
        }
        if superClass.fieldNum + fieldNum > maxFieldNum {
            fatalError()
        }
    }
    
    /// 执行指令
    public func executeInstruction(thread: ThreadObject) -> Virtual.result {
        self.thread = thread
        loadFrame()
        
        while true {
            guard let opCode = opCode else {
                return .success
            }
            switch opCode {
            case .LOAD_LOCAL_VAR:
                guard let byte = readByte() else {
                    fatalError()
                }
                push(value: self.thread!.stack[stackStart + Int(byte)])
            case .LOAD_THIS_FIELD:
                guard let fieldIndex = readByte() else {
                    fatalError()
                }
                guard let instanceObject = self.thread!.stack[stackStart].toInstanceObject() else {
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
                self.thread!.stack[stackStart + Int(byte)] = peek()
            case .LOAD_CONSTANT:
                guard let value = readShort() else {
                    fatalError()
                }
                push(value: self.fn!.constantsList[value])
            default: break
                
            }
        }
    }
}

extension Virtual {
    func push(value: AnyValue) {
        guard let thread = self.thread else {
            fatalError()
        }
        thread.esp += 1
        thread.stack[thread.esp] = value
    }
    
    func pop() -> AnyValue {
        guard let thread = self.thread else {
            fatalError()
        }
        thread.esp -= 1
        return thread.stack[thread.esp]
    }
    
    /// 丢弃
    func drop() {
        guard let thread = self.thread else {
            fatalError()
        }
        thread.esp -= 1
    }
    
    /// 获得栈顶的数据
    func peek() ->AnyValue {
        guard let thread = self.thread else {
            fatalError()
        }
        return thread.stack[thread.esp - 1]
    }
    
    /// 获得次栈顶的数据
    func peek2() -> AnyValue {
        guard let thread = self.thread else {
            fatalError()
        }
        return thread.stack[thread.esp - 2]
    }
    
    /// 读取1个字节
    func readByte() -> Byte? {
        guard fn != nil else {
            fatalError()
        }
        guard ip <= fn!.byteStream.count else {
            return nil
        }
        let byte = fn!.byteStream[ip]
        ip += 1
        return byte
    }
    
    /// 读取2个字节
    func readShort() -> Int? {
        guard fn != nil else {
            fatalError()
        }
        ip += 2
        guard ip - 2 <= fn!.byteStream.count, ip - 1 <= fn!.byteStream.count else {
            return nil
        }
        return Int(fn!.byteStream[ip - 2]) << 8 | Int(fn!.byteStream[ip - 1])
    }
    
    func storeFrame(frame: CallFrame, ip: Index) {
        frame.ip = ip
    }
    
    func loadFrame() {
        guard let thread = self.thread else {
            fatalError()
        }
        frame = thread.frames[thread.usedFrameNum - 1]
        
        guard let frame = frame else {
            fatalError()
        }
        
        stackStart = frame.stackStart
        ip = frame.ip
        fn = frame.closure.fn
    }
    
    func decode() {
        guard let byte = readByte() else {
            self.opCode = nil
            return
        }
        self.opCode = OP_CODE(rawValue: byte)
    }
}


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
            fn.constantsList[superClassIndex] = AnyValue(value: cls.superClass)
            ip += 2
        case .CREATE_CLOSURE:
            let fnIndex = Int(fn.byteStream[ip]) << 8 | Int(fn.byteStream[ip + 1])
            guard let fnObject = fn.constantsList[fnIndex].toFnObject() else {
                fatalError()
            }
            patchOperand(cls: cls, fn: fnObject)
            ip += getBytesOfByteCode(byteStream: fn.byteStream, constants: fn.constantsList, ip: ip - 1)
        case .END:
            return
        default:
            ip += getBytesOfByteCode(byteStream: fn.byteStream, constants: fn.constantsList, ip: ip - 1)
        }
    }
}
