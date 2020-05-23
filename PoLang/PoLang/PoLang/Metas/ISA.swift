//
//  ISA.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/20.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class ISA: NSObject {
    public enum ClassType {
        case none
        case num
        case bool
        case range
        case string
        case list
        case map
    
        case upValue

        case class_
        case instance
        
        case closure
        case thread
    }
    
    public var type: ClassType
    public var cls: ClassInfo?
    init(type: ClassType, cls: ClassInfo?) {
        self.type = type
        self.cls = cls
        super.init()
    }
}
