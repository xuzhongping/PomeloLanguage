//
//  Class.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public struct Method {
    enum MethodType {
        case none
        case native
        case script
        case call
    }
    var type: MethodType
    var imp: Any
}

public class Class {
    
    /// 指向metaClass
    var header: Header
    var superClass: Class?
    
    /// 域的个数存储在类中
    var fieldNum: Int = 0
    
    /// key: 方法签名 value: 方法实现
    var methods: [String: Method]
    var name: String
    
    init(header: Header, superClass: Class?, name: String) {
        self.header = header
        self.superClass = superClass
        self.name = name
        self.methods = [:]
    }

}
