//
//  List.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public class ListObject: ObjectProtocol {
    public var header: Header
    var container: [Any]
    init(virtual: Virtual) {
        //TODO: 设置ListClass
        self.header = Header(virtual: virtual, type: .list, cls: nil)
        self.container = []
    }
    
    public func removeAt(index: Int) {
        self.container.remove(at: index)
    }
    public func insertAt(index: Int, elem: Any) {
        self.container.insert(elem, at: index)
    }
}