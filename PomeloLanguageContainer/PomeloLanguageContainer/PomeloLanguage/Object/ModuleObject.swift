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
    public func defineVar(virtual: Virtual, name: String, value: AnyValue)  -> Index {
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
    
    /// 声明模块变量,不做重定义检查
    public func declareVar(virtual: Virtual, name: String, value: AnyValue) -> Index {
        guard name.count <= maxIdLength else {
            fatalError("length of identifier '\(name)' should be more than \(maxIdLength)")
        }
        moduleVarNames.append(name)
        moduleVarValues.append(value)
        return moduleVarNames.lastIndex
    }
    
}




