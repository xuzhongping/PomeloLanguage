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
    
    public var isDigit: Bool { (self >= "0" && self <= "9") }
    
    public var isEof: Bool { self == "\0" }
    
    public var isAlnum: Bool { isNumber || isLetter}
    
}

extension Index {
    public static var notFound: Index { -1 }

    public static var repeatDefine: Index { -1 }
}

extension Array {
    public var lastIndex: Index { count - 1 }
}

extension ScopeDepth {
    public static var module: ScopeDepth { -1 }
    
    public static var normal: ScopeDepth { 0 }

}

extension String {
    /// 小写字符开头便是局部变量
    public var isLocalName: Bool { at(index: 0)?.isLowercase ?? false }
}

