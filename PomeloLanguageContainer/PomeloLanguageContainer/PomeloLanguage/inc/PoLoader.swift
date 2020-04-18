//
//  Loader.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/4/18.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

class PoLoader: NSObject {
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
    static public func loadCore() -> String {
        return loadCode(name: "core", type: "po")
    }
}
