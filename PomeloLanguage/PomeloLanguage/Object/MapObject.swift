//
//  Map.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public class MapObject: ObjectProtocol {
    public var header: Header
    var contaniner: [String: Any]
    init(virtual: Virtual) {
        //TODO: 设置MapClass
        self.header = Header(virtual: virtual, type: .map, cls: nil)
        self.contaniner = [:]
    }
    public func set(key: String, value: Any) {
        self.contaniner[key] = value
    }
    public func get(key: String) -> Any? {
        return self.contaniner[key]
    }
    
}
