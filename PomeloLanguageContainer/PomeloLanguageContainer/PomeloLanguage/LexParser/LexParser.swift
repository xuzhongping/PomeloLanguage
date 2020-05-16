//
//  LexParser.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/21.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Foundation

public class Token {
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
    public typealias Status = LexStatus
    
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

    private static var keyboardsTable: [Keyword] {
        [
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
            Keyword(string: "this",     length: 4, type: .this),
            Keyword(string: "super",    length: 5, type: .super_),
            Keyword(string: "import",   length: 6, type: .import_)
        ]
    }

    public var virtual: Virtual
    
    /// 当前正在编译的模块
    public var curModule: ModuleObject
    
    /// 当前编译单元
    public var curCompileUnit: CompilerUnit?
    
    public var preToken: Token
    
    public var curToken: Token
    
    private  var file: String?
    
    private var code: String
    
    private var position: Index = 0
    
    private var curChar: Character? {
        get {
            return code.at(index: position)
        }
    }
    
    private var expectationRightParenNum: Int = 0
    
    public var line: Int = 1
    
    
    init(virtual: Virtual, moduleName: String, module: ModuleObject, code: String) {
        self.virtual = virtual
        self.curModule = module
        self.code = code
        self.preToken = Token()
        self.curToken = Token()
    }
    
    convenience init?(virtual: Virtual, moduleName: String, module: ModuleObject, file: String) {
        guard let handle = FileHandle(forReadingAtPath: file) else {
            fatalError()
        }
        guard let code = String(data: handle.readDataToEndOfFile(), encoding: .utf8) else {
            fatalError()
        }
        self.init(virtual: virtual,
                  moduleName: moduleName,
                  module: module,
                  code: code)
    }
    
    public func nextToken() {
        preToken = curToken
        curToken = Token()
        while true {
            skipBlanks()
            guard let char = self.curChar else {
                curToken.type = .eof
                return
            }
            if char.isEof() {
                curToken.type = .eof
                return
            }
            
            switch char {
            case ",":
                curToken.type = .comma
                curToken.value = ","
            case ":":
                curToken.type = .colon
            case "(":
                if expectationRightParenNum > 0 {
                    expectationRightParenNum += 1
                }
                curToken.type = .leftParen
            case ")":
                
                if expectationRightParenNum > 0 {
                    expectationRightParenNum -= 1
                    if expectationRightParenNum == 0 {
                        parseString()
                        return
                    }
                }
                curToken.type = .rightParen
            case "[":
                curToken.type = .leftBracket
            case "]":
                curToken.type = .rightBracket
            case "{":
                curToken.type = .leftBrace
            case "}":
                curToken.type = .rightBrace
            case ".":
                if matchNextChar(expected: ".") {
                    curToken.type = .dotDouble
                } else {
                    curToken.type = .dot
                }
            case "=":
                if matchNextChar(expected: "=") {
                    curToken.type = .equal
                } else {
                    curToken.type = .assign
                }
            case "+":
                curToken.type = .add
            case "-":
                curToken.type = .sub
            case "*":
                curToken.type = .mul
            case "/":
                curToken.type = .div
            case "%":
                curToken.type = .mod
            case "&":
                if matchNextChar(expected: "&") {
                    curToken.type = .logicAnd
                } else {
                    curToken.type = .bitAnd
                }
            case "|":
                if matchNextChar(expected: "|") {
                    curToken.type = .logicOr
                } else {
                    curToken.type = .bitOr
                }
            case "~":
                curToken.type = .bitNot
            case "?":
                curToken.type = .question
            case ">":
                if matchNextChar(expected: "=") {
                    curToken.type = .greateEqual
                } else if matchNextChar(expected: "<") {
                    curToken.type = .bitShiftLeft
                } else {
                    curToken.type = .greate
                }
            case "<":
                if matchNextChar(expected: "=") {
                    curToken.type = .lessEqual
                } else if matchNextChar(expected: "<") {
                    curToken.type = .bitShiftRight
                } else {
                    curToken.type = .less
                }
            case "!":
                if matchNextChar(expected: "=") {
                    curToken.type = .notEqual
                } else {
                    curToken.type = .logicNot
                }
            case "\"":
                parseString()
                return
            default:
                if char.isCased || char == "_" {
                    parseId()
                    return
                }
                if char == "#" && matchNextChar(expected: "!") {
                    skipAline()
                    continue
                }
                if char == "#" {
                    skipAline()
                    continue
                }
                if char.isWholeNumber {
                    parseNum()
                    return
                }
                fatalError("未识别的符号\(char) \(line)")
            }
            break
        }
        seekNext()
    }
}

extension LexParser {
    private func seekNext() {
       seek(offset: 1)
    }
   
    private func seek(offset: Int) {
       position += offset
   }
    
    private func matchNextChar(expected: Character) -> Bool {
        if lookNextChar() == expected {
            seekNext()
            return true
        }
        return false
    }
    
    private func skipBlanks() {
        while let character = curChar, character.isWhitespace {
            if character.isNewline {
                line += 1
            }
            seekNext()
        }
    }
    
    
    private func skipAline() {
        while true {
            guard let character = curChar,character != "\0" else {
                break
            }
            if character.isNewline {
                line += 1
                seekNext()
                break
            } else {
                seekNext()
            }
        }
    }
    
    public func consumeCurToken(expected: Token.TokenType, message: String) {
        guard curToken.type == expected else {
            fatalError(message)
        }
        nextToken()
    }
    
    public func matchCurToken(expected: Token.TokenType) -> Bool {
        guard curToken.type == expected else {
            return false
        }
        nextToken()
        return true
    }
}

extension LexParser {
    private func lookNextChar() -> Character? {
        return code.at(index: position + 1)
    }
}

extension LexParser {
    
    func isKeyword() -> Bool {
        for keyboard in LexParser.keyboardsTable {
            let subString = code.subString(range: NSRange(location: position, length: keyboard.length))
            if subString == keyboard.string && code.at(index: position + keyboard.length)?.isWhitespace ?? false{
                curToken.type = keyboard.type
                seek(offset: keyboard.length)
                return true
            }
        }
        return false
    }
    private func parseId() {
        if isKeyword() {
            return
        }
        
        var tempString = ""
        while let character = self.curChar,character.isCased || character == "_" {
            tempString.append(character)
            seekNext()
        }
        
        curToken.value = tempString
        curToken.type = .id
    }
}

// MARK: 解析数字
extension LexParser {
    
    /// 解析16进制数字
    private func parseHexNum() {
        var tempString = ""
        while let character = self.curChar,character.isHexDigit {
            tempString.append(character)
            seekNext()
        }
        curToken.value = Int(tempString)
    }
    
    /// 解析10进制数字
    private func parseDecNum() {
        var tempString = ""
        while let character = self.curChar,character.isDigit() {
            tempString.append(character)
            seekNext()
        }
        guard let character = self.curChar else {
            curToken.value = Int(tempString)
            return
        }
        guard character == "." && (lookNextChar()?.isDigit() ?? false) else {
            curToken.value = Int(tempString)
            return
        }
        tempString.append(".")
        seekNext()
        while let character = self.curChar,character.isDigit() {
            tempString.append(character)
            seekNext()
        }
        curToken.value = Double(tempString)
    }
    
    /// 解析8进制数字
    private func parseOctNum() {
        var tempString = ""
        while let character = self.curChar,character >= "0",character < "8" {
            tempString.append(character)
            seekNext()
        }
        curToken.value = Int(tempString)
    }
    /// 解析数字
    private func parseNum() {
        guard let character = self.curChar else { return }
        if character == "0" && matchNextChar(expected: "x") {
            seekNext()
            parseHexNum()
        } else if character == "0" && (lookNextChar()?.isHexDigit ?? false) {
            parseOctNum()
        } else {
            parseDecNum()
        }
        curToken.type = .num
    }
}

// MARK: 解析字符串
extension LexParser {
    private func parseString() {
        var tempString = ""
        while true {
            seekNext()
            guard let character = self.curChar, character != "\0" else {
                fatalError()
            }
            
            guard character != "\"" else {
                curToken.type = .string
                seekNext()
                break
            }
            
            /// 处理内嵌表达式 %(...)
            if character == "%" {
                if !matchNextChar(expected: "(") {
                    fatalError()
                }
                if expectationRightParenNum > 0 {
                    fatalError()
                }
                expectationRightParenNum = 1
                curToken.type = .interpolation
                break
            }
            
            if character == "\\" {
                seekNext()
                switch curChar {
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
        curToken.value = tempString
    }
}

