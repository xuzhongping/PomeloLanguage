//
//  NumObject.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/12.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class NumObject: BaseObject {
    var value: Double
    init(virtual: Virtual, value: Double) {
        self.value = value
        super.init(virtual: virtual, type: .num, cls: virtual.numClass)
    }
}
