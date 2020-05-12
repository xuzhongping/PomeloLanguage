//
//  NumObject.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/12.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

class NumObject: BaseObject {
    var value: Double
    init(virtual: Virtual) {
        self.value = 0
        super.init(virtual: virtual, type: .list, cls: nil)
    }
}
