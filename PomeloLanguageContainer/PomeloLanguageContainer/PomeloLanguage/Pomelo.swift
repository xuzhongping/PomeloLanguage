//
//  pomelo.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/12.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

class Pomelo {
    public static func run(file: String)  {
        let virtual = Virtual()
        
        let moduleObject = ModuleObject(name: "test", virtual: virtual)
        

        guard let lexParser = LexParser(virtual: virtual, moduleName: "test", module: moduleObject, file: file) else {
            fatalError()
        }
        
        while true {
            lexParser.nextToken()
            guard lexParser.status != .end else {
                return
            }
            
            guard let token = lexParser.curToken else {
                fatalError()
            }
            print("\(token.type):\(token.value ?? "")")
        }
    }
}
