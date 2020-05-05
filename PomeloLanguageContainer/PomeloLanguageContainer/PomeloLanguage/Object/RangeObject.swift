//
//  Range.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

/// 运行时结构
public class RangeObject: BaseObject {
    var from: Int
    var to: Int
    init(virtual: Virtual, from: Int, to: Int) {
        //TODO: 设置RangeClass
        self.from = from
        self.to = to
        super.init(virtual: virtual, type: .range, cls: nil)
    }
}
