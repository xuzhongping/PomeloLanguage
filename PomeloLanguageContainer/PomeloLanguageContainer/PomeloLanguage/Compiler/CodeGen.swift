//
//  CodeGen.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/3/30.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

/// 生成数字和字符串.nud()字面量指令
public func emitLiteral(unit: CompilerUnit, canAssign: Bool) {
    unit.emitLoadConstant(constant: AnyValue(value: unit.curLexParser.preToken?.value))
}
