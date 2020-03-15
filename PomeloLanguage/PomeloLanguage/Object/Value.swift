//
//  Value.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/15.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public class Value {
    enum ValueType {
        case null
        case true_
        case false_
        case num
        case string
        case obj
    }
    
    var type: ValueType
    
    var object: ObjectProtocol?
    
    var string: String?
    
    var num: Double
    
    init(type: ValueType) {
        self.type = type
        self.num = 0
    }
    
    convenience init(value: ObjectProtocol) {
        self.init(type: .obj)
        self.object = object
    }
    
    convenience init(value: Double) {
        self.init(type: .num)
        self.num = num
    }
    
    convenience init(value: String) {
        self.init(type: .string)
        self.string = string
    }
    
    convenience init(value: Bool) {
        if value == true {
            self.init(type: .true_)
        } else {
            self.init(type: .false_)
        }
    }
    
    public func equal(other: Value) -> Bool {
        guard type != other.type else {  return false }
        
        if type == .null {
            return other.type == .null
        }

        if type == .false_ {
            return other.type == .false_
        }

        if type == .true_ {
            return other.type == .true_
        }

        if type == .num {
            return num == other.num
        }
        return (object as AnyObject).isEqual(to: other.object as AnyObject)
    }
}

extension Value: Equatable {
    public static func == (lhs: Value, rhs: Value) -> Bool {
        return lhs.equal(other: rhs)
    }
}

extension Value {
    public func getClass(virtual: Virtual) -> ClassObject? {
        switch type {
        case .null:
            return virtual.nullClass
        case .false_:
            return virtual.boolClass
        case .true_:
            return virtual.boolClass
        case .num:
            return virtual.numClass
        case .string:
            return virtual.stringClass
        case .obj:
            return object?.header.cls
        }
    }
}

extension Value {
    public func toBool() -> Bool? {
        if type == .false_ {
            return false
        }
        if type == .true_ {
            return true
        }
        return nil
    }
    
    public func isClassObject(virtual: Virtual) -> Bool {
        return toClassObject(virtual: virtual) != nil
    }

    public func toClassObject(virtual: Virtual) -> ClassObject? {
        guard type == .obj else {
            return nil
        }
        return object as? ClassObject
    }
    
    public func isListObject(virtual: Virtual) -> Bool {
        return toListObject(virtual: virtual) != nil
    }
    
    public func toListObject(virtual: Virtual) -> ListObject? {
        guard type == .obj else {
            return nil
        }
        return object as? ListObject
    }
    
    public func isMapObject(virtual: Virtual) -> Bool {
        return toMapObject(virtual: virtual) != nil
    }
    
    public func toMapObject(virtual: Virtual) -> MapObject? {
       guard type == .obj else {
           return nil
       }
       return object as? MapObject
    }
    
    public func isRangeObject(virtual: Virtual) -> Bool {
        return toRangeObject(virtual: virtual) != nil
    }
    
    public func toRangeObject(virtual: Virtual) -> RangeObject? {
       guard type == .obj else {
           return nil
       }
       return object as? RangeObject
    }
    
    public func isThreadObject(virtual: Virtual) -> Bool {
        return toThreadObject(virtual: virtual) != nil
    }
    
    public func toThreadObject(virtual: Virtual) -> ThreadObject? {
       guard type == .obj else {
           return nil
       }
       return object as? ThreadObject
    }
}
