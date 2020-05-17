//
//  Module.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/16.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa


/// 模块对象
/// 编译时和运行时结构
public class ModuleObject: BaseObject {            
    public var moduleVarNames: [String]
    public var moduleVarValues: [AnyValue]
    
    var name: String
    init(name: String, virtual: Virtual) {
        self.name = name
        self.moduleVarNames = []
        self.moduleVarValues = []
        
        super.init(virtual: virtual, type: .module, cls: virtual.moduleClass)
    }
}




