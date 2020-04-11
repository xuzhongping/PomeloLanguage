//
//  LexParser.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/21.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Foundation

public class Token: NSObject {
    public enum TokenType {
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
        case null
        
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
    var value: Any?
    var line: Int = 0
}

public class LexParser: NSObject {
    public enum LexStatus {
        case begin
        case runing
        case end
    }
    
    private struct Keyword{
        var string: String
        var length: Int
        var type: Token.TokenType
    }
    
    private static var keyboardsTable: [Keyword] = [
        Keyword(string: "var",      length: 3, type: .var_),
        Keyword(string: "fun",      length: 3, type: .func_),
        Keyword(string: "if",       length: 2, type: .if_),
        Keyword(string: "else",     length: 4, type: .else_),
        Keyword(string: "true",     length: 3, type: .true_),
        Keyword(string: "false",    length: 5, type: .false_),
        Keyword(string: "while",    length: 5, type: .while_),
        Keyword(string: "for",      length: 3, type: .for_),
        Keyword(string: "break",    length: 5, type: .break_),
        Keyword(string: "continue", length: 8, type: .continue_),
        Keyword(string: "return",   length: 6, type: .return_),
        Keyword(string: "nil",      length: 3, type: .null),
        Keyword(string: "class",    length: 5, type: .class_),
        Keyword(string: "is",       length: 2, type: .is_),
        Keyword(string: "static",   length: 6, type: .static_),
        Keyword(string: "this",     length: 4, type: .var_),
        Keyword(string: "super",    length: 5, type: .super_),
        Keyword(string: "import",   length: 6, type: .import_)
    ]

    public var status: LexStatus
    
    public var preToken: Token?
    
    public var curToken: Token?
    
    public var virtual: Virtual
    
    /// 当前正在编译的模块
    public var curModule: ModuleObject
    
    /// 当前编译单元
    public var curCompileUnit: CompilerUnit?
    
    private  var file: String?
    
    private var code: String
    
    private var position: Int = 0
        
    private var seekCharacter: Character? {
        get {
            return code.at(index: position)
        }
    }
    
    private var expectationRightParenNum: Int = 0
    
    public var line: Int = 0
    
    
    init(virtual: Virtual, moduleName: String, module: ModuleObject, code: String) {
        self.virtual = virtual
        self.curModule = module
        self.code = code
        self.status = .begin
    }
    
    convenience init?(virtual: Virtual, moduleName: String, module: ModuleObject, file: String) {
        guard let handle = FileHandle(forReadingAtPath: file) else {
            return nil
        }
        guard let code = String(data: handle.readDataToEndOfFile(), encoding: .utf8) else {
            return nil
        }
        self.init(virtual: virtual, moduleName: moduleName, module: module, code: code)
    }
    @discardableResult
    public func nextToken() -> Token?{
        status = .runing
        
        preToken = curToken
        curToken = nil
        skipBlanks()
        
        guard let char = seekCharacter else {
            status = .end
            return nil
        }
        
        if char.isEof() {
            status = .end
            return nil
        }
        
        let token = Token()
        curToken = token
        token.type = .unknown
        switch char {
        case ",":
            token.type = .comma
            token.value = ","
        case ":":
            token.type = .colon
        case "(":
            token.type = .leftParen
            expectationRightParenNum += 1
        case ")":
            if expectationRightParenNum > 0 {
                token.type = .rightParen
                break
            }
            expectationRightParenNum -= 1
            if expectationRightParenNum == 0 {
                token.type = .rightParen
                break
            }
            try parseString()
            return curToken
        case "[":
            token.type = .leftBracket
        case "]":
            token.type = .rightBracket
        case "{":
            token.type = .leftBrace
        case "}":
            token.type = .rightBrace
        case ".":
            if matchNextCharacter(expected: ".") {
                token.type = .dotDouble
            } else {
                token.type = .dot
            }
        case "=":
            if matchNextCharacter(expected: "=") {
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
            if matchNextCharacter(expected: "/") || matchNextCharacter(expected: "*") {
                skipBlanks()
                return nil
            } else {
                token.type = .div
            }
        case "%":
            token.type = .mod
        case "&":
            if matchNextCharacter(expected: "&") {
                token.type = .logicAnd
            } else {
                token.type = .bitAnd
            }
        case "|":
            if matchNextCharacter(expected: "|") {
                token.type = .logicOr
            } else {
                token.type = .bitOr
            }
        case "~":
            token.type = .bitNot
        case "?":
            token.type = .question
        case ">":
            if matchNextCharacter(expected: "=") {
                token.type = .greateEqual
            } else if matchNextCharacter(expected: "<") {
                token.type = .bitShiftLeft
            } else {
                token.type = .greate
            }
        case "<":
            if matchNextCharacter(expected: "=") {
                token.type = .lessEqual
            } else if matchNextCharacter(expected: "<") {
                token.type = .bitShiftRight
            } else {
                token.type = .less
            }
        case "!":
            if matchNextCharacter(expected: "=") {
                token.type = .notEqual
            } else {
                token.type = .logicNot
            }
        case "\"":
            parseString()
            return curToken
        default:
            if char.isCased || char == "_" {
                parseId()
                return curToken
            }
            if char == "#" && matchNextCharacter(expected: "!") {
                skipAline()
                return nil
            }
            if char.isWholeNumber {
                parseNum()
                return curToken
            }
            fatalError()
        }
        seekNext()
        return curToken
    }
}

extension LexParser {

}


extension LexParser {
    private func lookNextCharacter() -> Character? {
        return code.at(index: position + 1)
    }
    private func seekNext() {
        seek(offset: 1)
    }
    
    private func seek(offset: Int) {
        position += offset
    }
    
    private func matchNextCharacter(expected: Character) -> Bool {
        if lookNextCharacter() == expected {
            seekNext()
            return true
        }
        return false
    }
    
    private func skipBlanks() {
        while let character = seekCharacter, character.isWhitespace {
            if character.isNewline {
                line += 1
            }
            seekNext()
        }
    }
    private func skipAline() {
        while let character = seekCharacter,character != "\0" {
            if character.isNewline {
                line += 1
                seekNext()
                break
            }
        }
    }
    
    public func consumeCurToken(expected: Token.TokenType, message: String) {
        guard curToken?.type == expected else {
            fatalError(message)
        }
        nextToken()
    }
    
    public func matchCurToken(expected: Token.TokenType) -> Bool {
        guard curToken?.type == expected else {
            return false
        }
        nextToken()
        return true
    }
}

extension LexParser {
    private func parseId() {
        if isKeyword() {
            seekNext()
            return
        }
        var tempString = ""
        while let character = self.seekCharacter,character.isCased {
            tempString.append(character)
            seekNext()
        }
        curToken?.value = tempString
        curToken?.type = .id
    }
    private func isKeyword() -> Bool {
        for keyboard in LexParser.keyboardsTable {
            let subString = code.subString(range: NSRange(location: position, length: keyboard.length))
            if subString == keyboard.string {
                curToken?.type = keyboard.type
                seek(offset: keyboard.length)
                return true
            }
        }
        return false
    }
}

// MARK: 解析数字
extension LexParser {
    
    /// 解析16进制数字
    private func parseHexNum() {
        var tempString = ""
        while let character = self.seekCharacter,character.isHexDigit {
            tempString.append(character)
            seekNext()
        }
        curToken?.value = Int(tempString)
    }
    
    /// 解析10进制数字
    private func parseDecNum() {
        var tempString = ""
        while let character = self.seekCharacter,character.isDigit() {
            tempString.append(character)
            seekNext()
        }
        guard let character = self.seekCharacter else {
            curToken?.value = Int(tempString)
            return
        }
        guard character == "." && (lookNextCharacter()?.isDigit() ?? false) else {
            curToken?.value = Int(tempString)
            return
        }
        tempString.append(".")
        seekNext()
        while let character = self.seekCharacter,character.isDigit() {
            tempString.append(character)
            seekNext()
        }
        curToken?.value = Double(tempString)
    }
    
    /// 解析8进制数字
    private func parseOctNum() {
        var tempString = ""
        while let character = self.seekCharacter,character >= "0",character < "8" {
            tempString.append(character)
            seekNext()
        }
        curToken?.value = Int(tempString)
    }
    /// 解析数字
    private func parseNum() {
        guard let character = self.seekCharacter else { return }
        guard let token = self.curToken else { return }
        if character == "0" && matchNextCharacter(expected: "x") {
            seekNext()
            parseHexNum()
        } else if character == "0" && (lookNextCharacter()?.isHexDigit ?? false) {
            parseOctNum()
        } else {
            parseDecNum()
        }
        token.type = .num
    }
}

// MARK: 解析字符串
extension LexParser {
    private func parseString() {
        var tempString = ""
        while true {
            seekNext()
            guard let character = self.seekCharacter, character != "\0" else {
                fatalError()
            }
            
            guard character != "\"" else {
                curToken?.type = .string
                seekNext()
                break
            }
            
            /// 处理内嵌表达式 %(...)
            if character == "%" {
                if !matchNextCharacter(expected: "(") {
                    fatalError()
                }
                if expectationRightParenNum > 0 {
                    fatalError()
                }
                expectationRightParenNum = 1
                curToken?.type = .interpolation
                break
            }
            
            if character == "\\" {
                seekNext()
                switch seekCharacter {
                case "0":
                    tempString.append("\\0")
                case "a":
                    tempString.append("\\a")
                case "b":
                    tempString.append("\\b")
                case "f":
                    tempString.append("\\f")
                case "n":
                    tempString.append("\\n")
                case "r":
                    tempString.append("\\r")
                case "t":
                    tempString.append("\\t")
                case "u":
                    //TODO: 需要处理unide
                    tempString.append("\\u")
                case "\"":
                    tempString.append("\\b")
                case "\\":
                    tempString.append("\\")
                default:
                    fatalError()
                }
            } else {
                tempString.append(character)
            }
        }
        curToken?.value = tempString
    }
}

