//
//  Module.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/16.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

/// 模块对象
public class ModuleObject: BaseObject {            
    public var moduleVarNames: [String]
    public var moduleVarValues: [AnyValue]
    
    var name: String?
    init(name: String, virtual: Virtual) {
        self.name = name
        self.moduleVarNames = []
        self.moduleVarValues = []
        
        super.init(virtual: virtual, type: .module, cls: nil)
    }
    
    /// 定义模块变量
    @discardableResult
    public func defineVar(virtual: Virtual, name: String, value: AnyValue)  -> Int {
        guard name.count <= maxIdLength else {
            fatalError("length of identifier '\(name)' should be more than \(maxIdLength)")
        }
        
        var symbolIndex = Index.repeatDefine
        if let nameIndex = moduleVarNames.firstIndex(of: name) {
            
            let oldValue = moduleVarValues[nameIndex]
            // 处理已声明未定义，除此之外就是重复定义
            if oldValue.isPlaceholder() {
                moduleVarValues[nameIndex] = value
                symbolIndex = nameIndex
            }
        } else {
            moduleVarNames.append(name)
            moduleVarValues.append(value)
            symbolIndex = moduleVarValues.lastIndex
        }
        
        return symbolIndex
    }
    
    /// 声明模块变量
    public func declareModuleVar(virtual: Virtual, name: String, value: AnyValue) -> Int {
        return defineVar(virtual: virtual, name: name, value: AnyValue.placeholder)
    }
    
}


/// 获取一个模块
public func getModule(virtual: Virtual, name: String) -> ModuleObject? {
    return virtual.allModules[name]?.toModuleObject()
}


/// 获取核心模块
public func getCoreModule(virtual: Virtual) -> ModuleObject? {
    return getModule(virtual: virtual, name: ModuleNameCore)
}


/// 加载一个模块
public func loadModule(virtual: Virtual, name: String, code: String)  -> ThreadObject? {
    var module = getModule(virtual: virtual, name: name)

    if module == nil {
        module = ModuleObject(name: name, virtual: virtual)
        virtual.allModules[name] = AnyValue(value: module)
        guard let coreModule = getCoreModule(virtual: virtual) else {
            fatalError("core module is null")
        }
        for i in 0..<coreModule.moduleVarNames.count {
            let name = coreModule.moduleVarNames[i]
            let value = coreModule.moduleVarValues[i]
            module!.defineVar(virtual: virtual, name: name, value: value)
        }
    }
    
    let fnObj = compileModule(virtual: virtual, module: module!, code: code)
    let closureObj = ClosureObject(virtual: virtual, fn: fnObj)
    
    return ThreadObject(virtual: virtual, closure: closureObj)
}

public func executeModule(virtual: Virtual, name: String, code: String) -> Virtual.result {
    let _ = loadModule(virtual: virtual, name: name, code: code)
    return .success
}

