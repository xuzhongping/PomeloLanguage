//
//  ModuleMeta.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/20.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class ModuleMeta: NSObject {
    var name: String
    public var moduleVarNames: [String]
    public var moduleVarValues: [AnyValue]
    public init(name: String) {
        self.name = name
        self.moduleVarNames = []
        self.moduleVarValues = []
    }
}
