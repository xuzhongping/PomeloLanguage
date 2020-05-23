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
    public var module: ModuleInfo!
    
    public var allModules: [String: ModuleInfo] = [:]

    public var classOfClass: ClassInfo!
    public var objectClass: ClassInfo!
    public var stringClass: ClassInfo!
    public var mapClass: ClassInfo!
    public var rangeClass: ClassInfo!
    public var listClass: ClassInfo!
    public var nullClass: ClassInfo!
    public var boolClass: ClassInfo!
    public var numClass: ClassInfo!
    public var systemClass: ClassInfo!
    
    public var closureClass: ClassInfo!
    public var threadClass: ClassInfo!
    public var moduleClass: ClassInfo!
    
    
    public convenience init(lexParser: LexParser, module: ModuleInfo) {
        self.init()
        self.lexParser = lexParser
        self.module = module
    }
    
    public func loadModule(name: ModuleName, code: String) -> ModuleInfo {
        if let module = allModules[name] {
            return module
        }
        let module = ModuleInfo(name: name, code: code)
        
        let coreModule = loadCoreModule()
        
        for item in coreModule.moduleVarNames {
            
        }
        
        allModules[name] = module
        return module
    }
    
    public func loadCoreModule() -> ModuleInfo {
        if let module = allModules[ModuleName.core] {
            return module
        }
        let module = ModuleInfo(name: ModuleName.core, code: "")
        allModules[ModuleName.core] = module
        return module
    }
}
