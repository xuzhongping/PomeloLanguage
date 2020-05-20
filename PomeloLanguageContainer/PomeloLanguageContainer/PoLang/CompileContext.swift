//
//  CompileContext.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/20.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class CompileContext: NSObject {
    public var lexParser: LexParser!
    public var module: ModuleObject!
    
    public var allModules: [String: ModuleObject] = [:]

    public var classOfClass: ClassObject!
    public var objectClass: ClassObject!
    public var stringClass: ClassObject!
    public var mapClass: ClassObject!
    public var rangeClass: ClassObject!
    public var listClass: ClassObject!
    public var nullClass: ClassObject!
    public var boolClass: ClassObject!
    public var numClass: ClassObject!
    public var fnClass: ClassObject!
    public var threadClass: ClassObject!
    public var moduleClass: ClassObject!
    public var systemClass: ClassObject!
    
    public convenience init(lexParser: LexParser, module: ModuleObject) {
        self.init()
        self.lexParser = lexParser
        self.module = module
    }
}
