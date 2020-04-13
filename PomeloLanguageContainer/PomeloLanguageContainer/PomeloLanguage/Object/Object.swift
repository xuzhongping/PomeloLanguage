//
//  Object.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/21.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Foundation


/// 普通实例对象
class instanceObject: BaseObject {
    var ivarTable: [String: Any]
    init(cls: ClassObject, virtual: Virtual) {
        self.ivarTable = [:]
        super.init(virtual: virtual, type: .instance, cls: cls)
    }
}
