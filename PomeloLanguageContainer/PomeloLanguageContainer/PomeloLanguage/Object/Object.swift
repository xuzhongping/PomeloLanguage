//
//  Object.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/21.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Foundation


/// 所有对象都需要遵守此协议
public protocol ObjectProtocol {
    var header: Header { get set }
}


/// 普通实例对象
class instanceObject: NSObject, ObjectProtocol {
    var header: Header
    var ivarTable: [String: Any]
    init(cls: ClassObject, virtual: Virtual) {
        self.header = Header(virtual: virtual, type: .instance, cls: cls)
        self.ivarTable = [:]
    }
}
