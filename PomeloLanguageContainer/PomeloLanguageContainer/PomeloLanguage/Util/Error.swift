//
//  Error.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/15.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa


public extension LexParser {
    enum LexParserError: Error {
        case unknown
        case general(message: String)
        case create
        case parseString
        case parseNumber
        case parseId
    }
}

public enum BuildError: Error {
    case unknown
    case general(message: String)
    case undefined(symbol: String)
    case repeatDefinition(symbol: String)
}

public enum RuntimeError: Error {
    case unknown
    case general(message: String)
}
