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
    
    public override var description: String {
        var description = "<AnyValue"
        description.append("(value:\(value ?? "null")")
        description.append(")>")
        return description
    }
}

extension AnyValue {
    
    public func toStringObject() -> StringObject? {
        guard let obj = value as? StringObject else {
            return nil
        }
        return obj
    }
    
    public func toBoolObject() -> BoolObject? {
        guard let obj = value as? BoolObject else {
            return nil
        }
        return obj
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
    
    public func toModuleObject() -> ModuleObject? {
       guard let obj = value as? ModuleObject else {
           return nil
       }
       return obj
    }
    
    public func toNumObject() -> NumObject? {
        guard let value = value as? NumObject else {
            return nil
        }
        return value
    }
}

extension AnyValue {
    
    public func isStringObject() -> Bool {
        return value is StringObject
    }
    
    public func isBoolObject() -> Bool {
        return value is BoolObject
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
    
    public func isModuleObject() -> Bool {
       return value is ModuleObject
    }
    
    public func isNull() -> Bool {
        return value == nil
    }
    
    public func isPlaceholder() -> Bool {
        return self == AnyValue.placeholder
    }
    
    public func isNumObject() -> Bool {
        return value is NumObject
    }
}

extension AnyValue {
    public func getClass(virtual: Virtual) -> ClassObject {
        switch value {
        case is StringObject:
            return virtual.stringClass
        case is BoolObject:
            return virtual.boolClass
        case is NumObject:
            return virtual.numClass
        case is ClassObject:
            return toClassObject()!.header.cls!
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
        case is ModuleObject:
            return virtual.moduleClass
        default:
            return virtual.nullClass
        }
    }
}

extension AnyValue {
    public static var placeholder: AnyValue {
        return AnyValue(value: "pomepo.placehodler")
    }
}
