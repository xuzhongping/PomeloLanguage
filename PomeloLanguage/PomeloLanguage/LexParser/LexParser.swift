//
//  LexParser.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/21.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Foundation

class Token {
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
    var type: TokenType = .unknown
    var string: String?
    var line: Int = 0
}

class LexParser {
    
    enum LexParserError: Error {
        case unknown
        case create
    }

    
    
    enum LexStatus {
        case begin
        case runing
        case end
    }
    
    
    var file: String?
    
    var code: String
    
    var position: Int = 0
        
    var char: Character? {
        get {
            guard position < code.count else {
                return nil
            }
            return code.at(index: position)
        }
    }
    
    var status: LexStatus = .begin
    
    var expectationRightParenNum: Int = 0
    
    var virtual: Virtual
    
    var line: Int = 0
    
    
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
    
    public func getNextToken() throws -> Token? {
        self.status = .runing
        skipBlanks()
        guard let char = char,char != "\0" else {
            self.status = .end
            return nil
        }
        
        let token = Token()
        token.type = .unknown
        switch char {
        case ",":
            token.type = .comma
            token.string = ","
        case ":":
            token.type = .colon
        case "(":
            token.type = .leftParen
            expectationRightParenNum += 1
        case ")":
            if expectationRightParenNum > 0 {
                expectationRightParenNum -= 1
                if expectationRightParenNum == 0 {
                    parseString(token: token)
                    break;
                }
            }
            token.type = .rightParen
        case "[":
            token.type = .leftBracket
        case "]":
            token.type = .rightBracket
        case "{":
            token.type = .leftBrace
        case "}":
            token.type = .rightBrace
        case ".":
            if matchNextChar(expected: ".") {
                token.type = .dotDouble
            } else {
                token.type = .dot
            }
        case "=":
            if matchNextChar(expected: "=") {
                token.type = .equal
            } else {
                token.type = .assign
            }
        case "+":
            token.type = .add
        case "-":
            token.type = .sub
        case "*":
            token.type = .mul
        case "/":
            if matchNextChar(expected: "/") || matchNextChar(expected: "*") {
                skipBlanks()
            } else {
                token.type = .div
            }
        case "%":
            token.type = .mod
        case "&":
            if matchNextChar(expected: "&") {
                token.type = .logicAnd
            } else {
                token.type = .bitAnd
            }
        case "|":
            if matchNextChar(expected: "|") {
                token.type = .logicOr
            } else {
                token.type = .bitOr
            }
        case "~":
            token.type = .bitNot
        case "?":
            token.type = .question
        case ">":
            if matchNextChar(expected: "=") {
                token.type = .greateEqual
            } else if matchNextChar(expected: "<") {
                token.type = .bitShiftLeft
            } else {
                token.type = .greate
            }
        case "<":
            if matchNextChar(expected: "=") {
                token.type = .lessEqual
            } else if matchNextChar(expected: "<") {
                token.type = .bitShiftRight
            } else {
                token.type = .less
            }
        case "!":
            if matchNextChar(expected: "=") {
                token.type = .notEqual
            } else {
                token.type = .logicNot
            }
        case "\"":
            parseString(token: token)
            return token
        default:
            if char.isCased || char == "_" {
                parseId(token: token)
                return token
            }
            if char == "#" && matchNextChar(expected: "!") {
                skipAline()
                return nil
            }
            throw LexParserError.unknown
        }

        guard char != "\0"  else {
            self.status = .end
            return nil
        }
        getNextChar()
        return token
    }
}

extension LexParser {
    private func lookAheadChar() -> Character {
        return code.at(index: position + 1)
    }
    private func getNextChar() {
        position += 1
    }
    
    private func matchNextChar(expected: Character) -> Bool {
        if lookAheadChar() == expected {
            getNextChar()
            return true
        }
        return false
    }
    
    private func skipBlanks() {
        while let char = self.char, char.isWhitespace {
            if char.isNewline {
                line += 1
            }
            getNextChar()
        }
    }
    private func skipAline() {
        while let char = char,char != "\0" {
            if char.isNewline {
                line += 1
                getNextChar()
                break
            }
        }
    }
}

extension LexParser {
    private func parseString(token: Token) {
        token.type = .string
        getNextChar()
    }
    
    private func parseId(token: Token) {
        token.type = .string
        getNextChar()
    }
}

extension String {
    public func at(index: Int) -> Character {
        let i = self.index(self.startIndex, offsetBy: index)
        return self[i]
    }
}

