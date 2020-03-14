//
//  Range.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

class Range: ObjectProtocol {
    var header: Header
    var from: Int
    var to: Int
    init(virtual: Virtual, from: Int, to: Int) {
        //TODO: 设置RangeClass
        self.header = Header(virtual: virtual, type: .range, cls: nil)
        self.from = from
        self.to = to
    }
}
