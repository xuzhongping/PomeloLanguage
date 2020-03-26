//
//  Virtual.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/10.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public class Virtual: NSObject {
    
    public enum result {
        case success
        case error
    }
    
    var allocatedBytes: Int
    var lexParser: LexParser?
    var allObjectHeader: Header?
    
    /// Class类
    var classOfClass: ClassObject!
    
    /// Object类
    var objectClass: ClassObject!
    
    /// String类
    var stringClass: ClassObject!
    
    /// Map类
    var mapClass: ClassObject!
    
    /// Range类
    var rangeClass: ClassObject!
    
    /// List类
    var listClass: ClassObject!
    
    /// Null类
    var nullClass: ClassObject!
    
    /// Bool类
    var boolClass: ClassObject!
    
    /// Num类
    var numClass: ClassObject!
    
    /// Fn类
    var fnClass: ClassObject!
    
    /// Thread类
    var threadClass: ClassObject!
    
    /// 所有模块
    public var allModules: [String: ModuleObject]
    
    /// 所有类的方法名集合(去重)
    public var allMethodNames: [String]
    override init() {
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
