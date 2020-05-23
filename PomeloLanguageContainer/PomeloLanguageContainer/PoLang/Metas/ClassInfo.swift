//
//  ClassMeta.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/20.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class ClassInfo: NSObject {
    public var isa: ISA
    
    public var superCls: ClassInfo?
    public var name: String
    
    public var fieldNum: Int
    
    public var methodImps: [Method]
    public var methodNames: [String]
    
    public init(name:String, isa: ISA) {
        self.name = name
        self.isa = isa
        
        self.fieldNum = 0
        self.methodImps = []
        self.methodNames = []
    }
}
