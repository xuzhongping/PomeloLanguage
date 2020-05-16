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

public class LexMetaInfo {
    public struct Keyword{
        var string: String
        var length: Int
        var type: Token.TokenType
    }

    public static var keyboards: [Keyword] {
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

}


public class LexParser: NSObject {
    
    
    
    public var virtual: Virtual
    /// 当前正在编译的模块
    public var curModule: ModuleObject
    /// 当前编译单元
    public var curCompileUnit: CompilerUnit?
    
    public var line: Int = 1
    
    private var file: String?
    private var code: String
    
    public var preToken: Token
    public var curToken: Token
    private var position: Index = 0
    
    private var curChar: Character? {
        return code.at(index: position)
    }
    
    private var expn: Int = 0
    
    init(virtual: Virtual, moduleName: String, module: ModuleObject, file: String?, code: String) {
        self.virtual = virtual
        self.curModule = module
        self.file = file
        self.code = code
        self.preToken = Token()
        self.curToken = Token()
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
            
            if char.isEof {
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
                if expn > 0 {
                    expn += 1
                }
                curToken.type = .leftParen
            case ")":
                if expn > 0 {
                    expn -= 1
                    if expn == 0 {
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
                if matchChar(expected: ".") {
                    curToken.type = .dotDouble
                } else {
                    curToken.type = .dot
                }
            case "=":
                if matchChar(expected: "=") {
                    curToken.type = .equal
                } else {
                    curToken.type = .assign
                }
            case "+":
                curToken.type = .add
            case "-":
                if lookNextChar()?.isDigit ?? false {
                    parseNum()
                    return
                } else {
                    curToken.type = .sub
                }
            case "*":
                curToken.type = .mul
            case "/":
                curToken.type = .div
            case "%":
                curToken.type = .mod
            case "&":
                if matchChar(expected: "&") {
                    curToken.type = .logicAnd
                } else {
                    curToken.type = .bitAnd
                }
            case "|":
                if matchChar(expected: "|") {
                    curToken.type = .logicOr
                } else {
                    curToken.type = .bitOr
                }
            case "~":
                curToken.type = .bitNot
            case "?":
                curToken.type = .question
            case ">":
                if matchChar(expected: "=") {
                    curToken.type = .greateEqual
                } else if matchChar(expected: "<") {
                    curToken.type = .bitShiftLeft
                } else {
                    curToken.type = .greate
                }
            case "<":
                if matchChar(expected: "=") {
                    curToken.type = .lessEqual
                } else if matchChar(expected: "<") {
                    curToken.type = .bitShiftRight
                } else {
                    curToken.type = .less
                }
            case "!":
                if matchChar(expected: "=") {
                    curToken.type = .notEqual
                } else {
                    curToken.type = .logicNot
                }
            case "\"":
                parseString()
                return
                
            case "#":
                skipAline()
                continue
                
            case "_":
                parseId()
                return
            default:
                if char.isCased {
                    parseId()
                    return
                }
                
                if char.isWholeNumber {
                    parseNum()
                    return
                }
                fatalError("未识别的符号\(char) \(line)")
            }
            break
        }
        advance()
    }
}

extension LexParser {
    
    private func advance() {
       advance(offset: 1)
    }
    
    private func advance(offset: Int) {
       position += offset
    }
    
    private func matchChar(expected: Character) -> Bool {
        guard lookNextChar() == expected else {
            return false
        }
        advance()
        return true
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
    private func skipBlanks() {
        while let character = curChar, character.isWhitespace {
            if character.isNewline {
                line += 1
            }
            advance()
        }
    }

    private func skipAline() {
        while true {
            guard let character = curChar,character != "\0" else {
                break
            }
            if character.isNewline {
                line += 1
                advance()
                break
            } else {
                advance()
            }
        }
    }
}

extension LexParser {
    private func lookNextChar() -> Character? {
        return code.at(index: position + 1)
    }
}


// MARK: 解析标识符
extension LexParser {
    
    func detectKeyword() -> Bool {
        for keyword in LexMetaInfo.keyboards {
            let prefix = code.subString(range: NSRange(location: position, length: keyword.length))
            let suffix = code.at(index: position + keyword.length)
            if prefix == keyword.string && suffix?.isWhitespace ?? false{
                curToken.type = keyword.type
                advance(offset: keyword.length)
                return true
            }
        }
        return false
    }
    
    private func parseId() {
        if detectKeyword() {
            return
        }
        
        var str = ""
        while let character = self.curChar, character.isAlnum || character == "_" {
            str.append(character)
            advance()
        }
        
        curToken.value = str
        curToken.type = .id
    }
}

// MARK: 解析数字
extension LexParser {
    
    /// 解析16进制数字
    private func parseHexNum() {
        var str = ""
        while let character = self.curChar,character.isHexDigit {
            str.append(character)
            advance()
        }
        curToken.value = Int(str)
    }
    
    /// 解析10进制数字
    private func parseDecNum() {
        var str = ""
        
        if let character = self.curChar, character == "-" {
            str.append(character)
            advance()
        }
        
        while let character = self.curChar,character.isDigit {
            str.append(character)
            advance()
        }
        guard let character = self.curChar, character != "\0" else {
            curToken.value = Int(str)
            return
        }
        
        guard character == "." && (lookNextChar()?.isDigit ?? false) else {
            curToken.value = Int(str)
            return
        }
        
        str.append(".")
        advance()
        while let character = self.curChar,character.isDigit {
            str.append(character)
            advance()
        }
        curToken.value = Double(str)
    }
    
    /// 解析8进制数字
    private func parseOctNum() {
        var str = ""
        while let character = self.curChar,character >= "0",character < "8" {
            str.append(character)
            advance()
        }
        curToken.value = Int(str)
    }
    /// 解析数字
    private func parseNum() {
        guard let character = self.curChar, character != "\0" else {
            fatalError()
        }
        if character == "0" && lookNextChar() == "x" {
            parseHexNum()
        } else if character == "0" && (lookNextChar()?.isDigit ?? false) {
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
        var str = ""
        while true {
            advance()
            guard let character = self.curChar, character != "\0" else {
                fatalError()
            }
            
            if character == "\"" {
                curToken.type = .string
                advance()
                break
            }
            
            /// 处理内嵌表达式 %(...)
            if character == "%" {
                if !matchChar(expected: "(") {
                    fatalError()
                }
                if expn > 0 {
                    fatalError()
                }
                expn = 1
                curToken.type = .interpolation
                advance()
                break
            }
            
            if character == "\\" {
                advance()
                switch curChar {
                case "0":
                    str.append("\\0")
                case "a":
                    str.append("\\a")
                case "b":
                    str.append("\\b")
                case "f":
                    str.append("\\f")
                case "n":
                    str.append("\\n")
                case "r":
                    str.append("\\r")
                case "t":
                    str.append("\\t")
                case "u":
                    //TODO: 需要处理unide
                    str.append("\\u")
                case "\"":
                    str.append("\\b")
                case "\\":
                    str.append("\\")
                default:
                    fatalError()
                }
            } else {
                str.append(character)
            }
        }
        curToken.value = str
    }
}

