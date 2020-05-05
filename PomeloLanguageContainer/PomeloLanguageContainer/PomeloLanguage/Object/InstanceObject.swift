//
//  Object.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/21.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Foundation

/// 运行时结构
/// 普通实例对象
public class InstanceObject: BaseObject {
    var fields: [AnyValue]
    init(cls: ClassObject, virtual: Virtual) {
        self.fields = Array(repeating: AnyValue.placeholder, count: cls.fieldNum)
        super.init(virtual: virtual, type: .instance, cls: cls)
    }
}
