//
//  Pomelo.swift
//  PoLang
//
//  Created by xuzhongping on 2020/5/23.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

class Pomelo: NSObject {
    private var virtual: Virtual
    
    private var context: RuntimeContext
    
    override init() {
        
        context = RuntimeContext()
        
        let coreModule = context.loadCoreModule()
        
        guard let coreFn = compileModule(context: context, module: coreModule) else {
            fatalError("core module compile fail!")
        }
        
        virtual = Virtual()
        
        virtual.execute(context: context, fn: coreFn)
    }
    
    func runModule(name: ModuleName, code: String) {
        let module  = virtual.context.loadModule(name: name, code: code)
        
        guard let fn = compileModule(context: context, module: module) else {
            fatalError("\(name) module compile fail!")
        }
        
        virtual.execute(context: context, fn: fn)
    }
}
