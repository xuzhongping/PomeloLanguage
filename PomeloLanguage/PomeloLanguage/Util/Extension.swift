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
}
