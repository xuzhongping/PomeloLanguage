//
//  pomelo.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/12.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

class Pomelo {
    public static func run(file: String) throws {
        let virtual = Virtual()

        guard let lexParser = LexParser(virtual: virtual, file: file) else {
            throw LexParser.LexParserError.create
        }
        while lexParser.status != .end {
            guard let token = try lexParser.getNextToken() else {
                break
            }
            print("\(token.type):\(token.string ?? "")")
        }
    }
}
