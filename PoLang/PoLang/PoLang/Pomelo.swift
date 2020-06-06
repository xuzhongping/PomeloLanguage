//
//  Pomelo.swift
//  PoLang
//
//  Created by xuzhongping on 2020/5/23.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

//Pomelo运行过程:
//1. 创建虚拟机和运行上下文
//2. 将代码抽象成模块对象，编译这个模块对象
//3. 编译过程中生成的各种比如类信息、模块信息、类的方法和域信息都保存到运行上下文中
//4. 编译的结果是一段字节码(操作码+操作数)
//5. 虚拟机执行操作码，执行的过程也是操作运行上下文

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
