//
//  Module.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/16.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

/// 模块对象
public class ModuleObject: NSObject, ObjectProtocol {
    
    public typealias Var = (name: String, value: AnyValue)
    
    public var header: Header
    
    /// 被引用，但是未定义的变量名集合
    var undefinedIvarNames: Set<String>
    
    /// 已被定义过的变量表
    public var vars: [Var]
    
    var name: String?
    init(name: String, virtual: Virtual) {
        self.header = Header(virtual: virtual, type: .module, cls: nil) // module为元信息对象，不属于任何一个类
        self.name = name
        self.vars = []
        self.undefinedIvarNames = Set<String>()
    }
    
    @discardableResult
    public func defineVar(virtual: Virtual, name: String, value: AnyValue)  -> Int {
        guard name.count <= maxIdLength else {
            fatalError()
        }
        /// 如果被提前引用，这次是实际定义，就从提前引用表删除，下面会定义
        if undefinedIvarNames.contains(name) {
            undefinedIvarNames.remove(name)
        }
        
        if vars.contains(where: { (iname,_) -> Bool in return iname == name }) {
           fatalError()
        }
        vars.append((name,value))
        return vars.count - 1
    }
    
    /// 声明模块变量
    public func declareModuleVar(virtual: Virtual, name: String, value: AnyValue) -> Int {
        vars.append((name, value))
        return vars.count - 1
    }
    
}


/// 获取一个模块
/// - Parameters:
///   - virtual: 虚拟机
///   - name: 模块名
public func getModule(virtual: Virtual, name: String) -> ModuleObject? {
    return virtual.allModules[name]
}

public func getCoreModule(virtual: Virtual) -> ModuleObject? {
    return getModule(virtual: virtual, name: ModuleNameCore)
}


/// 加载一个模块
/// - Parameters:
///   - virtual: 虚拟机
///   - name: 模块名
///   - code: 源码
public func loadModule(virtual: Virtual, name: String, code: String)  -> ThreadObject? {
    var module = getModule(virtual: virtual, name: name)
    if module == nil {
        module = ModuleObject(name: name, virtual: virtual)
        if let module = module {
            virtual.allModules[name] = module
            if let coreModule = getCoreModule(virtual: virtual) {
                for (name,value) in coreModule.vars {
                    module.defineVar(virtual: virtual, name: name, value: value)
                }
            }
        }
    }
    if let module = module {
        let fnObj = try compileModule(virtual: virtual, module: module, code: code)
        let closureObj = ClosureObject(virtual: virtual, fn: fnObj)
        return ThreadObject(virtual: virtual, closure: closureObj)
    }
    return nil
}

public func executeModule(virtual: Virtual, name: String, code: String) -> Virtual.result {
    let _ = try? loadModule(virtual: virtual, name: name, code: code)
    return .success
}

