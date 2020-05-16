//
//  BoolObject.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/16.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class BoolObject: BaseObject {
    var value: Bool
    init(virtual: Virtual, value: Bool) {
        self.value = value
        super.init(virtual: virtual, type: .bool, cls: virtual.boolClass)
    }
}
