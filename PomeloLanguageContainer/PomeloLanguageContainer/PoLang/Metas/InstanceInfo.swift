//
//  InstanceMeta.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/20.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class InstanceInfo: NSObject {
    public var isa: ISA
    public var field: [AnyValue]
    public init(cls: ClassInfo, isa: ISA) {
        self.isa = ISA(type: .instance, cls: cls)
        self.field = []
    }
}
