//
//  Map.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public class MapObject: BaseObject {
    var contaniner: [String: Any]
    init(virtual: Virtual) {
        //TODO: 设置MapClass
        self.contaniner = [:]
        super.init(virtual: virtual, type: .map, cls: nil)
    }
    public func set(key: String, value: Any) {
        self.contaniner[key] = value
    }
    public func get(key: String) -> Any? {
        return self.contaniner[key]
    }
    
}
