//
//  Client.swift
//  PoLang
//
//  Created by xuzhongping on 2020/5/23.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class Client: NSObject {
    
    static func runFile(file: URL) {
        
    }
    
    static func runCommandLine() {
        print("welcome to pomelo language!")
        print("version: \(Pomelo.version)");
        let pomelo = Pomelo()
        while true {
            print(">> ", terminator: "")
            guard let line = readLine() else {
                break
            }
            guard line != "exit" else {
                break
            }
            pomelo.run(name: ModuleName.command, code: line)
        }
    }
}
