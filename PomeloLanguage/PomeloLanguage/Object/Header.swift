//
//  Header.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public class Header {
    
    enum ObjectType {
        case none
        case class_
        case list
        case map
        case module
        case range
        case string
        case upValue
        case function
        case closure
        case instance
        case thread
    }
    
    var type: ObjectType
    var cls: Class?
    var next: Header? //TODO: header链表需要记录
    var dark: Bool
    
    init(virtual: Virtual, type: ObjectType, cls: Class?) {
        self.type = type
        self.cls = cls
        self.dark = false
        if let header = virtual.allObjectHeader {
            self.next = header
        }
//        virtual.allObjectHeader = self
    }
}

