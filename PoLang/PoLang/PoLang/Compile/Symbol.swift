//
//  Symbol.swift
//  PoLang
//
//  Created by xuzhongping on 2020/5/24.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class Signature {
    public enum SignatureType {
        case construct // 构造函数 xxx(_,...)
        case method    // 方法 xxx(_,...)
        case getter    // Getter xxx
        case setter    // Setter xxx=(_)
        case subscriptGetter    // xxx[_,...]
        case subscriptSetter    // xxx[_,...] = (_)
    }
    var type: SignatureType
    var name: String
    var argNum: Int
    public init(type: SignatureType, name: String, argNum: Int) {
        self.type = type
        self.name = name
        self.argNum = argNum

    }
    
    var toString: String {
        var signatureStr = name
        switch type {
            case .getter:
                break
            case .setter:
                signatureStr.append(contentsOf: "=(_)")
            case .construct, .method:
                signatureStr.append("(")
                for i in 0..<argNum {
                    signatureStr.append("_")
                    if i < argNum - 1 { signatureStr.append(",") }
                }
                signatureStr.append(")")
            case .subscriptGetter:
                signatureStr.append("[")
                for i in 0..<argNum {
                    signatureStr.append("_")
                    if i < argNum - 1 { signatureStr.append(",") }
                }
                signatureStr.append("]")
            case .subscriptSetter:
                signatureStr.append("[")
                for i in 0..<argNum {
                    signatureStr.append("_")
                    if i < argNum - 1 { signatureStr.append(",") }
                }
                signatureStr.append(contentsOf: "]=(_)")
        }
        return signatureStr
    }
}
