//
//  Map.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public class MapObject: BaseObject {
    
    var value: [String: Any]
    init(virtual: Virtual) {
        self.value = [:]
        super.init(virtual: virtual, type: .map, cls: nil)
    }

}
