//
//  Constant.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/16.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa




public typealias ModuleName = String

public extension ModuleName {
    static var core: ModuleName { "Core" }
    static var command: ModuleName { "Command" }
}


public typealias ClassName = String

public extension ClassName {
    static var object: ClassName { "Object" }
    
    static var metaObject: ClassName { "MetaObject" }
    
    static var cls: ClassName { "Class" }
    
    static var string: ClassName { "String" }
    
    static var map: ClassName { "Map" }
    
    static var range: ClassName { "Range" }
    
    static var list: ClassName { "List" }
    
    static var null: ClassName { "Null" }
    
    static var bool: ClassName { "Bool" }
    
    static var num: ClassName { "Num" }
    
    static var fn: ClassName { "Fn" }
    
    static var thread: ClassName { "Thread" }
    
    static var module: ClassName { "Module" }
    
    static var system: ClassName { "System" }
}


public typealias Env = String
public extension Env {
    static var coreModulePath: String? { Bundle.main.path(forResource: "core", ofType: "po") }
}


public typealias Limit = Int
public extension Limit {
    static let localVarNum = 128
    static let upvalueNum = 128
    static let idLength = 128
    static let methodNameLength = 128
    static let argNum = 16
    static let sigNum = 128
    static let fieldNum = 128
}
