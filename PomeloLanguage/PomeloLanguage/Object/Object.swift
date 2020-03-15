//
//  Object.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/21.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Foundation


/// 所有对象都需要遵守此协议
public protocol ObjectProtocol {
    var header: Header{set get}
}

/// 模块对象
public class ModuleObject: ObjectProtocol {
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


/// 普通实例对象
class instanceObject: ObjectProtocol {
    var header: Header
    var ivarTable: [String: Any]
    init(cls: ClassObject, virtual: Virtual) {
        self.header = Header(virtual: virtual, type: .instance, cls: cls)
        self.ivarTable = [:]
    }
}
