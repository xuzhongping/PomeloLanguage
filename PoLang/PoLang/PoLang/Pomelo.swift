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
    
    override init() {
        
        virtual = Virtual()
        
        let coreModule = virtual.context.loadCoreModule()
        
        guard let coreFn = compileModule(module: coreModule) else {
            fatalError("core module compile fail!")
        }
        
        virtual.execute(fn: coreFn)
    }
    
    func runModule(name: ModuleName, code: String) {
        let module  = virtual.context.loadModule(name: name, code: code)
        
        guard let coreFn = compileModule(module: module) else {
            fatalError("\(name) module compile fail!")
        }
        
        virtual.execute(fn: coreFn)
    }
}
