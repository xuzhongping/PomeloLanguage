//
//  Constant.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/16.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa



public typealias ModuleName = String

extension ModuleName {
    public static var core: ModuleName { "Core" }
}


public typealias ClassName = String

extension ClassName {
    public static var object: ClassName { "Object" }
    
    public static var metaObject: ClassName { "MetaObject" }
    
    public static var cls: ClassName { "Class" }
    
    public static var string: ClassName { "String" }
    
    public static var map: ClassName { "Map" }
    
    public static var range: ClassName { "Range" }
    
    public static var list: ClassName { "List" }
    
    public static var null: ClassName { "Null" }
    
    public static var bool: ClassName { "Bool" }
    
    public static var num: ClassName { "Num" }
    
    public static var fn: ClassName { "Fn" }
    
    public static var thread: ClassName { "Thread" }
}



