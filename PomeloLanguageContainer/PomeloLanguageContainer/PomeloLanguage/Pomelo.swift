//
//  pomelo.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/12.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

class Pomelo {
//    public static func run(file: String)  {
//        let virtual = Virtual()
//
//        let moduleObject = ModuleObject(name: "test", virtual: virtual)
//
//
//        guard let lexParser = LexParser(virtual: virtual, moduleName: "test", module: moduleObject, file: file) else {
//            fatalError()
//        }
//
//        while true {
//            lexParser.nextToken()
//            guard lexParser.status != .end else {
//                return
//            }
//
//            guard let token = lexParser.curToken else {
//                fatalError()
//            }
//            print("\(token.type):\(token.value ?? "")")
//        }
//    }
    
    
    /// 运行脚本文件
    /// - Parameter file: 文件名
    public static func run(file: String) {
        let virtual = Virtual()
        
        let code = Loader.loadModule(name: file)
        
        let result = executeModule(virtual: virtual, name: file, code: code)
        print(result)
    }
    
    
    /// 运行脚本字符串
    /// - Parameter cli: 命令行中的输入
    public static func run(cli: String) {
        
    }
}
