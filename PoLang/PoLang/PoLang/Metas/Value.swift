//
//  Value.swift
//  PomeloLanguageContainer
//
//  Created by xuzhongping on 2020/5/23.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class Value: NSObject {
    
    public typealias List = Array<Value>
    
    public typealias Map = Dictionary<String, Value>
    
    private var value: Any?
    
    init(value: Any?) {
        self.value = value
    }
}

extension Value {
    public static var placeholder: Value {
        return Value(value: "pomelo.placeholder")
    }
}

extension Value {
    
    public var isString: Bool { value is String }
    
    public var isBool: Bool { value is Bool }
    
    public var isClass: Bool { value is ClassInfo }
    
    public var isInstance: Bool { value is InstanceInfo }
    
    public var isList: Bool { value is List }
    
    public var isMap: Bool { value is Map }
    
    public var isRange: Bool { value is NSRange}
    
    public var isThread: Bool { value is ThreadInfo }
    
    public var isClosure: Bool { value is ClosureInfo }
    
    public var isFn: Bool { value is FnInfo }
    
    public var isModule: Bool { value is ModuleInfo }
    
    public var isNull: Bool { value == nil }
    
    public var isPlaceholder: Bool { self == Value.placeholder }
    
    public var isNum: Bool { value is Double }
}

extension Value {
    public var toString: String? {
        guard let obj = value as? String else {
            return nil
        }
        return obj
    }
    
    public var toBool: Bool? {
        guard let obj = value as? Bool else {
            return nil
        }
        return obj
    }
    
    public var toClass: ClassInfo? {
        guard let obj = value as? ClassInfo else {
            return nil
        }
        return obj
    }
    
    public var toInstance: InstanceInfo? {
        guard let obj = value as? InstanceInfo else {
            return nil
        }
        return obj
    }
    
    public var toList: List? {
        guard let obj = value as? Array<Value> else {
            return nil
        }
        return obj
    }
    

    public var toMap: Map? {
       guard let obj = value as? Dictionary<String, Value> else {
           return nil
       }
       return obj
    }
    
    public var toRange: NSRange? {
       guard let obj = value as? NSRange else {
           return nil
       }
       return obj
    }
    
    public var toThread: ThreadInfo? {
       guard let obj = value as? ThreadInfo else {
           return nil
       }
       return obj
    }
    
    public var toClosure: ClosureInfo? {
       guard let obj = value as? ClosureInfo else {
           return nil
       }
       return obj
    }
    
    public var toFn: FnInfo? {
       guard let obj = value as? FnInfo else {
           return nil
       }
       return obj
    }
    
    public var toModule: ModuleInfo? {
       guard let obj = value as? ModuleInfo else {
           return nil
       }
       return obj
    }
    
    public var toNum: Double? {
        guard let value = value as? Double else {
            return nil
        }
        return value
    }
}

extension Value {
    public func getClass(context: RuntimeContext) -> ClassInfo {
        switch value {
        case is String:
            return context.stringClass
        case is Bool:
            return context.boolClass
        case is Double:
            return context.numClass
        case is List:
            return context.listClass
        case is Map:
            return context.mapClass
        case is NSRange:
            return context.rangeClass
        case is ThreadInfo:
            return context.threadClass
        case is ClosureInfo:
            return context.closureClass
        case is ModuleInfo:
            return context.moduleClass
        case is ClassInfo:
            return toClass!.isa.cls!
        case is InstanceInfo:
            return toInstance!.isa.cls!
        default:
            return context.nullClass
        }
    }
}
