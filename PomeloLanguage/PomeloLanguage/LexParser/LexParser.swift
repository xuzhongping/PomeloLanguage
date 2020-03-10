//
//  LexParser.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/21.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Foundation

class LexParser {

    enum TokenType {
        case unknown
        case num
        case string
        case id
        case interpolation
        
        case var_
        case func_
        case if_
        case else_
        case true_
        case false_
        case while_
        case for_
        case break_
        case continue_
        case return_
        case nil_
        
        case class_
        case this
        case static_
        case is_
        case super_
        case import_
        
        case comma
        case colon
        case leftParen
        case rightParen
        case leftBracket
        case rightBracket
        case leftBrace
        case rightBrace
        case dot
        case dotDouble
        
        case add
        case sub
        case mul
        case div
        case mod
        
        case assign
        
        case bitAnd
        case bitOr
        case bitNot
        case bitShiftLeft
        case bitShiftRight
        
        case logicAnd
        case logicOr
        case logicNot
        
        case equal
        case notEqual
        case greate
        case greateEqual
        case less
        case lessEqual
        
        case question
        
        case eof
    }
    
    struct Token {
        var type: TokenType = .unknown
        var string: String?
        var line: Int = -1
    }
    
    var file: String?
    
    var code: String
    
    var position: Int64 = 0
    
    var next: Int64 = 0
    
    var char: Character?
    
    var curToken: Token?
    
    var preToken: Token?
    
    var expectationRightParenNum: Int = 0
    
    var virtual: Virtual
    
    var line: Int64 = 0
    
    
    init(virtual: Virtual, code: String) {
        self.virtual = virtual
        self.code = code
    }
    
    convenience init?(virtual: Virtual, file: String) {
        guard let handle = FileHandle(forReadingAtPath: file) else {
            return nil
        }
        guard let code = String(data: handle.readDataToEndOfFile(), encoding: .utf8) else {
            return nil
        }
        self.init(virtual: virtual, code: code)
    }
    
    public func getNextToken() -> Token? {
        skipBlanks()
        preToken = curToken
        var token = Token()
        token.type = .unknown
        while let char = char,char != "\0" {
            switch char {
            case ",":
                token.type = .comma
            case ":":
                token.type = .colon
            case "(":
//                token.type = .comma
            case ")":
//                token.type = .comma
            default:
                
            }
        }
    }
}

extension LexParser {
    private func lookAheadChar() -> Character {
        let index = code.index(code.startIndex, offsetBy: Int(next))
        return code[index]
    }
    private func getNextChar() {
        let index = code.index(code.startIndex, offsetBy: Int(next))
        char = code[index]
        next += 1
    }
    
    private func matchNextChar(expected: Character) -> Bool {
        if lookAheadChar() == expected {
            getNextChar()
            return true
        }
        return false
    }
    
    private func skipBlanks() {
        guard let char = char else { return }
        while char.isWhitespace {
            if char.isNewline {
                line += 1
            }
            getNextChar()
        }
    }
}

