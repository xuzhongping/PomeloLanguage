//
//  List.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

/// 运行时结构
public class ListObject: BaseObject {
    var value: [Any]
    init(virtual: Virtual) {
        self.value = []
        super.init(virtual: virtual, type: .list, cls: virtual.listClass)
    }
}

