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
}
