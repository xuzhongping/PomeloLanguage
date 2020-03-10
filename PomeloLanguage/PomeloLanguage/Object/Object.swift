//
//  Object.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/21.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Foundation

class ObjectHeader {
    enum ObjectType {
        case none
        case class_
        case list
        case map
        case module
        case range
        case string
        case upvalue
        case function
        case closure
        case instance
        case thread
    }
    
    var type: ObjectType = .none
    var dark: Bool = false
    var cls: Class
    var next: ObjectHeader?
    
    init(cls: Class) {
        self.cls = cls
    }
}

class Value {
    enum ValueType {
        case none
        case null
        case false_
        case true_
        case num
        case obj
    }
    var type: ValueType = .none
    var num: Double = 0
    var obj: ObjectHeader?
}

class Method {
    enum MethodType {
        case none
        case native
        case script
        case call
    }
    var type: MethodType = .none
}


class Class {
    var objHeader: ObjectHeader?
    var superClass: Class?
    var fieldNum: Int32 = 0
    var method: [Method]?
}
