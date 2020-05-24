//
//  ModuleMeta.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/20.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class ModuleInfo: NSObject {
    var name: String
    var moduleVarNames: [String]
    var moduleVarValues: [Value]
    
    init(name: String) {
        self.name = name
        self.moduleVarNames = []
        self.moduleVarValues = []
    }
    
    @discardableResult
    func declareModuleVar(_ name: String) -> Index {
        guard name.count <= Limit.idLength else {
            fatalError("模块变量名过长:\(name)!")
        }
        
        if let index = moduleVarNames.firstIndex(of: name) {
            return index
        }
        
        moduleVarNames.append(name)
        moduleVarValues.append(Value.placeholder)
        return moduleVarNames.lastIndex
    }
    
    @discardableResult
    func defineModuleVar(_ name: String, _ value: Value) -> Index {
        guard name.count <= Limit.idLength else {
            fatalError("模块变量名过长:\(name)!")
        }
        
        if let nameIndex = moduleVarNames.firstIndex(of: name) {
            if moduleVarValues[nameIndex].isPlaceholder {
                moduleVarValues[nameIndex] = value
                return nameIndex
            }
            fatalError("模块变量重复定义:\(name)!")
        }
        
        moduleVarNames.append(name)
        moduleVarValues.append(value)
        return moduleVarNames.lastIndex
    }
}
