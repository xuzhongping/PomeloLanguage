//
//  Virtual.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/10.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public class Virtual {
    
    public enum result {
        case success
        case error
    }
    
    var allocatedBytes: Int
    var lexParser: LexParser?
    var allObjectHeader: Header?
    
    /// 所有模块
    public var allModules: [String: ModuleObject]
    
    /// 所有类的方法名集合(去重)
    public var allMethodNames: [String]
    init() {
        allocatedBytes = 0
        lexParser = nil
        allObjectHeader = nil
        allModules = [:]
        allMethodNames = []
    }
    
    public static func create() -> Virtual {
        let virtual = Virtual()
        buildCore(virtual: virtual)
        return virtual
    }
//    var classOfClass: Class
//    var objectClass: Class
//    var stringClass: Class
//    var mapClass: Class
//    var rangeClass: Class
//    var listClass: Class
//    var nullClass: Class
//    var boolClass: Class
//    var numClass: Class
//    var fnClass: Class
//    var threadClass: Class
//    
//    init() {
//        let classHeader = Header(virtual: nil, type: .class_, cls: nil)
//        stringClass = Class(header: classHeader, superClass: objectClass, name: "String")
//        mapClass = Class(header: classHeader, superClass: objectClass, name: "Map")
//        rangeClass = Class(header: classHeader, superClass: objectClass, name: "Range")
//        listClass = Class(header: classHeader, superClass: objectClass, name: "List")
//        nullClass = Class(header: classHeader, superClass: objectClass, name: "Null")
//        boolClass = Class(header: classHeader, superClass: objectClass, name: "Bool")
//        numClass = Class(header: classHeader, superClass: objectClass, name: "Num")
//        fnClass = Class(header: classHeader, superClass: objectClass, name: "Fn")
//        threadClass = Class(header: classHeader, superClass: objectClass, name: "Thread")
//    }
    
}
