//
//  StringObject.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/16.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class StringObject: BaseObject {
    var value: String
    init(virtual: Virtual, value: String) {
        self.value = value
        super.init(virtual: virtual, type: .string, cls: virtual.stringClass)
    }
}
