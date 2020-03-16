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
    public var header: Header
    
    /// 被引用，但是未定义的变量名集合
    var undefinedIvarNames: SymbolSet<String>
    
    /// 已被定义过的变量表
    var ivarTable: SymbolTable<String, Value>
    
    var name: String
    init(name: String, virtual: Virtual) {
        self.header = Header(virtual: virtual, type: .module, cls: nil) // module为元信息对象，不属于任何一个类
        self.name = name
        self.ivarTable = [:]
        self.undefinedIvarNames = SymbolSet<String>()
    }
}

public func defineModuleVar(virtual: Virtual,module: ModuleObject, name: String, value: Value) throws {
    guard name.count <= maxIdLength else {
        throw BuildError.unknown
    }
    
    /// 如果被提前引用，这次是实际定义，就从提前引用表删除，下面会定义
    if module.undefinedIvarNames.contains(name) {
        module.undefinedIvarNames.remove(name)
    }
    
    /// 如果没定义过，就直接定义
    guard let _ = module.ivarTable[name] else {
        module.ivarTable[name] = value
        return
    }
    
    /// 重复定义
    throw BuildError.repeatDefinition(symbol: name)
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
public func loadModule(virtual: Virtual, name: String, code: String) -> ThreadObject? {
    var module = getModule(virtual: virtual, name: name)
    if module == nil {
        module = ModuleObject(name: name, virtual: virtual)
        if let module = module {
            virtual.allModules[name] = module
            if let coreModule = getCoreModule(virtual: virtual) {
                for (name,value) in coreModule.ivarTable {
                    try! defineModuleVar(virtual: virtual, module: module, name: name, value: value)
                }
            }
        }
    }
    if let module = module {
        let fnObj = compileModule(virtual: virtual, module: module, code: code)
        let closureObj = ClosureObject(virtual: virtual, fn: fnObj)
        return ThreadObject(virtual: virtual, closure: closureObj)
    }
    return nil
}

public func executeModule(virtual: Virtual, name: String, code: String) -> Virtual.result {
    let _ = loadModule(virtual: virtual, name: name, code: code)
    return .success
}

