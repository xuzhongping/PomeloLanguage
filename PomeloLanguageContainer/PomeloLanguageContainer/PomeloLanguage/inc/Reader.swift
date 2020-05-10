//
//  Reader.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/10.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

class Loader: NSObject {
    static private func loadCode(name: String, type: String) -> String {
        guard let file = Bundle.main.path(forResource: name, ofType: type) else {
            fatalError()
        }
        
        guard let handle = FileHandle(forReadingAtPath: file) else {
            fatalError()
        }
        
        guard let code = String(data: handle.readDataToEndOfFile(), encoding: .utf8) else {
            fatalError()
        }
        return code
    }
}

extension Loader {
    static public func loadModule(name: String) -> String {
        return loadCode(name: name, type: "po")
    }
    
    static public func loadCoreModule() -> String {
        return loadModule(name: "core")
    }
}
