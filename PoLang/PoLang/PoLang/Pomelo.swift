//
//  Pomelo.swift
//  PoLang
//
//  Created by xuzhongping on 2020/5/23.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class Pomelo: NSObject {
    
    static var version: String { "0.0.1" }
    
    private var virtual: Virtual
    
    private var context: RuntimeContext
    
    override init() {
        
        context = RuntimeContext()
        
        let coreModule = context.loadCoreModule()
        
        guard let path = Env.coreModulePath else {
            fatalError("核心模块加载失败")
        }
        
        guard let handle = FileHandle(forReadingAtPath: path) else {
            fatalError("核心模块加载失败")
        }
        
        guard let code = String(data: handle.readDataToEndOfFile(), encoding: .utf8) else {
            fatalError("核心模块加载失败")
        }
        
        guard let coreFn = compileModule(context: context, module: coreModule, code: code) else {
            fatalError("核心模块编译失败!")
        }
        
        virtual = Virtual()
        
        virtual.execute(context: context, fn: coreFn)
    }
    
    func run(name: ModuleName, code: String) {
        let module  = context.loadModule(name: name)
        
        guard let fn = compileModule(context: context, module: module, code: code) else {
            fatalError("\(name) module compile fail!")
        }
        
        virtual.execute(context: context, fn: fn)
    }
}
