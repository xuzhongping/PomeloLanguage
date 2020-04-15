//
//  Basic.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/3/29.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class BaseObject: NSObject{
    public var header: Header
    public init(virtual: Virtual, type: Header.ObjectType, cls: ClassObject?){
        header = Header(virtual: virtual, type: type, cls: cls)
        super.init()
    }
}


public class AnyValue: NSObject {
    private var value: Any?
    init(value: Any?) {
        self.value = value
    }
}

extension AnyValue {
    public func toBool() -> Bool? {
        guard let bool = value as? Bool else {
            return nil
        }
        return bool
    }
    
    public func toClassObject() -> ClassObject? {
        guard let obj = value as? ClassObject else {
            return nil
        }
        return obj
    }
    
    public func toInstanceObject() -> InstanceObject? {
        guard let obj = value as? InstanceObject else {
            return nil
        }
        return obj
    }
    
    public func toListObject() -> ListObject? {
        guard let obj = value as? ListObject else {
            return nil
        }
        return obj
    }
    

    public func toMapObject() -> MapObject? {
       guard let obj = value as? MapObject else {
           return nil
       }
       return obj
    }
    
    public func toRangeObject() -> RangeObject? {
       guard let obj = value as? RangeObject else {
           return nil
       }
       return obj
    }
    
    public func toThreadObject() -> ThreadObject? {
       guard let obj = value as? ThreadObject else {
           return nil
       }
       return obj
    }
    
    public func toClosureObject() -> ClosureObject? {
       guard let obj = value as? ClosureObject else {
           return nil
       }
       return obj
    }
    
    public func toFnObject() -> FnObject? {
       guard let obj = value as? FnObject else {
           return nil
       }
       return obj
    }
}

extension AnyValue {
    public func isBool() -> Bool {
        return value is Bool
    }
    
    public func isClassObject() -> Bool {
        return value is ClassObject
    }
    
    public func isInstanceObject() -> Bool {
        return value is InstanceObject
    }
    
    public func isListObject() -> Bool {
        return value is ListObject
    }
    
    public func isMapObject() -> Bool {
       return value is MapObject
    }
    
    public func isRangeObject() -> Bool {
       return value is RangeObject
    }
    
    public func isThreadObject() -> Bool {
       return value is ThreadObject
    }
    
    public func isClosureObject() -> Bool {
       return value is ClosureObject
    }
    
    public func isFnObject() -> Bool {
       return value is FnObject
    }
}

extension AnyValue {
    public func getClass(virtual: Virtual) -> ClassObject {
        switch value {
        case is Bool:
            return virtual.boolClass
        case is ClassObject:
            return virtual.classOfClass
        case is InstanceObject:
            return toInstanceObject()!.header.cls!
        case is ListObject:
            return virtual.listClass
        case is MapObject:
            return virtual.mapClass
        case is RangeObject:
            return virtual.rangeClass
        case is ThreadObject:
            return virtual.threadClass
        case is FnObject:
            return virtual.fnClass
        default:
            return virtual.nullClass
        }
    }
}
