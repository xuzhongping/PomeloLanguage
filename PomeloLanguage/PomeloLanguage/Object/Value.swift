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
        case bool
        case num
        case obj
    }
    
    var type: ValueType
    var value: Any?
    init(type: ValueType, value: Any) {
        self.type = type
        self.value = value
    }
    
    public func getClass(virtual: Virtual) -> Class? {
        
        return nil
    }
    public func equal(other: Value) -> Bool {
        guard type != other.type else {  return false }
        
        switch type {
        case .null:
            return nullEqual(other: other)
        case .bool:
            return boolEqual(other: other)
        case .num:
            return numEqual(other: other)
        case .obj:
            return objEqual(other: other)
        default:
            return false
        }
    }
    
    private func nullEqual(other: Value) -> Bool {
        return value == nil && other.value == nil
    }
    
    private func boolEqual(other: Value) -> Bool {
        guard let lhs = value as? Bool  else {
            return false
        }
        
        guard let rhs = other.value as? Bool else {
            return false
        }
        return lhs == rhs
    }
    
    private func numEqual(other: Value) -> Bool {
        guard let lhs = value as? Double  else {
            return false
        }
        guard let rhs = other.value as? Double else {
            return false
        }
        return lhs == rhs
    }
        
    private func objEqual(other: Value) -> Bool {
        let lhs = value as AnyObject
        let rhs = other.value as AnyObject
        return lhs.isEqual(rhs)
    }
}

extension Value: Equatable {
    public static func == (lhs: Value, rhs: Value) -> Bool {
        return lhs.equal(other: rhs)
    }
}


//public func nullToValue() -> Value {
//    return Value(type: .null, value: AnyObject("Null"))
//}
//
//public func boolToValue(value: Bool) -> Value {
//    return Value(type: .bool, value: value)
//}
//
//public func numToValue(value: Any) -> Value {
//    return Value(type: .num, value: value)
//}
//
//public func objToValye(value: AnyObject) -> Value {
//    return Value(type: .obj, value: value)
//}
//
//
//public func valueToNull(value: Value) -> String? {
//    return value.value as? String
//}
//
//public func valueToBool(value: Value) -> Bool? {
//    return value.value as? Bool
//}
//
//public func valueToObj(value: Value) -> AnyObject? {
//    return value.value as AnyObject
//}
