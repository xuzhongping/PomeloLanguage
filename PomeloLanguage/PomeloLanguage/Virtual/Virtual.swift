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
    
    var classOfClass: ClassObject!
    var objectClass: ClassObject!
    var stringClass: ClassObject!
    var mapClass: ClassObject!
    var rangeClass: ClassObject!
    var listClass: ClassObject!
    var nullClass: ClassObject!
    var boolClass: ClassObject!
    var numClass: ClassObject!
    var fnClass: ClassObject!
    var threadClass: ClassObject!
    
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
    
}
