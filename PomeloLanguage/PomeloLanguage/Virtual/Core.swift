//
//  Core.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public func executeModule(virtual: Virtual, moduleName: String, moduleCode: String) -> Virtual.result {
    return .error
}

public func buildCore(virtual: Virtual) {
    let coreModuleFlag = "core"
    let coreModule = ModuleObject(name: coreModuleFlag, virtual: virtual)
    virtual.allModules[coreModuleFlag] = coreModule
}
