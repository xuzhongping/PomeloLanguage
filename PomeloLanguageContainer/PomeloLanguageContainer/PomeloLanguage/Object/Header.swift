//
//  Header.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

/// 编译时和运行时结构
public class Header: NSObject {
    
    public enum ObjectType {
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
        
        case function
        case closure
        case thread
        case module
    }
    
    var type: ObjectType
    var cls: ClassObject?
    var next: Header? //TODO: header链表需要记录
    var dark: Bool
    
    init(virtual: Virtual, type: ObjectType, cls: ClassObject?) {
        self.type = type
        self.cls = cls
        self.dark = false
        
        if let header = virtual.allObjectHeader {
            self.next = header
        }
    }
}

