//
//  Command.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/16.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

class Command: NSObject {
    
    func scanf() -> String? {
        let input = String(data: FileHandle.standardInput.availableData, encoding: String.Encoding.utf8)
        guard let str = input else {
            return nil
        }
        let index = str.index(str.endIndex, offsetBy: -1)
        return str.substring(to: index)
    }
    
    func run(){
        print("pomelo")
        print("version: \(0.0)");
        while true {
            print(">> ", terminator: "")
            guard let line = scanf() else {
                break
            }
            guard line != "exit" else {
                break
            }
            Pomelo.run(code: line)
        }
//        Pomelo.run(code: "System.print("hello world!")")
    }
    
    
    
}
