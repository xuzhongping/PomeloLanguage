//
//  extension.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

extension String {
    
    public func at(index: Int) -> Character? {
        guard index < self.count else {
            return nil
        }
        let i = self.index(self.startIndex, offsetBy: index)
        return self[i]
    }
    
    public func subString(range: NSRange) -> String? {
        guard range.location + range.length < self.count else {
            return nil
        }
        let startIndex = self.index(self.startIndex, offsetBy: range.location)
        let endIndex = self.index(startIndex, offsetBy: range.length)
        return String(self[startIndex..<endIndex])
    }
    
    public func firstIsLowercase() -> Bool {
        guard let char = at(index: 0) else {
            return false
        }
        return char.isLowercase
    }
}

extension Character {
    public func isDigit() -> Bool {
        return (self >= "0" && self <= "9")
    }
    public func isEof() -> Bool {
        return self == "\0"
    }
}

extension Index {
    public static var notFound: Index {
        return -1
    }
    
    public static var repeatDefine: Index {
        return -1
    }
}

extension Array {
    public var lastIndex: Int {
        return count - 1
    }
}

extension ScopeDepth {
    public static var module: ScopeDepth {
        return -1
    }
    
    public static var normal: ScopeDepth {
        return 0
    }
}
