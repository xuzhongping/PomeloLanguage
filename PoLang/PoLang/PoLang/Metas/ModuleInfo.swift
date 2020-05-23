//
//  ModuleMeta.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/20.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class ModuleInfo: NSObject {
    var name: String
    public var moduleVarNames: [String]
    public var moduleVarValues: [Value]
    public init(name: String, code: String) {
        self.name = name
        self.moduleVarNames = []
        self.moduleVarValues = []
    }
}
