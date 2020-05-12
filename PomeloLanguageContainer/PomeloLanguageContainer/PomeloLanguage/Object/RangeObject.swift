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
    var value: NSRange
    
    init(virtual: Virtual, from: Int, length: Int) {
        //TODO: 设置RangeClass
        self.value = NSRange(location: from, length: length)
        super.init(virtual: virtual, type: .range, cls: nil)
    }
}
