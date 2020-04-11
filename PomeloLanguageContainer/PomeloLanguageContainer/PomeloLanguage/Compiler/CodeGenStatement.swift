//
//  CodeGenStatement.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/4/11.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

/// 编译语句
public func compileStatment(unit: CompilerUnit) {
    if unit.curLexParser.matchCurToken(expected: .if_) {
        compileIfStatment(unit: unit)
    }
}

/// 编译if语句
public func compileIfStatment(unit: CompilerUnit) {
    unit.curLexParser.consumeCurToken(expected: .leftParen, message: "missing '(' after if!")
    expression(unit: unit, rbp: .lowest)
    unit.curLexParser.consumeCurToken(expected: .rightParen, message: "missing ')' before '{' in if!")
    
    let falseBranchStart = emitInstrWithPlaceholder(unit: unit, opCode: .JUMP_IF_FALSE)
    compileStatment(unit: unit)
    
    if unit.curLexParser.matchCurToken(expected: .else_) {
        let falseBranchEnd = emitInstrWithPlaceholder(unit: unit, opCode: .JUMP)
        emitPatchPlaceholder(unit: unit, absIndex: falseBranchStart)
        
        compileStatment(unit: unit)
        emitPatchPlaceholder(unit: unit, absIndex: falseBranchEnd)
    } else {
        emitPatchPlaceholder(unit: unit, absIndex: falseBranchStart)
    }
}

/// 编译while语句
public func compileWhileStatment(unit: CompilerUnit) {
    
    /// 进入循环前的设置
    func enterLoopSetting(unit: CompilerUnit, loop: Loop) {
        loop.condStartIndex = unit.fn.byteStream.count - 1
        loop.scopeDepth = unit.scopeDepth
        loop.enclosingLoop = unit.curLoop
        unit.curLoop = loop
    }
    
    /// 编译循环体
    func compileLoopBody(unit: CompilerUnit) {
        unit.curLoop?.bodyStartIndex = unit.fn.byteStream.count
        compileStatment(unit: unit)
    }
    
    func leaveLoopSetting(unit: CompilerUnit) {
        guard let loop = unit.curLoop else {
            fatalError("not in loop")
        }
        let loopBackOffset = unit.fn.byteStream.count - loop.condStartIndex + 2
        writeShortByteCode(unit: unit,
                           code: .LOOP,
                           operand: loopBackOffset)
        emitPatchPlaceholder(unit: unit, absIndex: loop.exitIndex)
        var index = loop.bodyStartIndex
        let loopEndIndex = unit.fn.byteStream.count
        while index < loopEndIndex {
            if OP_CODE.END.rawValue == unit.fn.byteStream[index] {
                unit.fn.byteStream[index] = OP_CODE.JUMP.rawValue
                emitPatchPlaceholder(unit: unit, absIndex: index + 1)
                index += 3
            } else {
                index += 1 + getBytesOfByteCode(byteStream: unit.fn.byteStream,
                                                constants: unit.fn.constantsList,
                                                ip: index)
            }
        }
        unit.curLoop = loop.enclosingLoop
    }
    
    let loop = Loop()
    enterLoopSetting(unit: unit, loop: loop)
    unit.curLexParser.consumeCurToken(expected: .leftParen, message: "expect '(' befor condition!")
    loop.exitIndex = emitInstrWithPlaceholder(unit: unit, opCode: .JUMP_IF_FALSE)
    compileLoopBody(unit: unit)
    leaveLoopSetting(unit: unit)
}

func getBytesOfByteCode(byteStream: [Byte], constants: [AnyValue], ip: Int) -> Int {
    switch OP_CODE(rawValue: byteStream[ip]) {
    case .CONSTRUCT,
         .RETURN,
         .END,
         .CLOSE_UPVALUE,
         .PUSH_NULL,
         .PUSH_FALSE,
         .PUSH_TRUE,
         .POP:
        return 0
    case .CREATE_CLASS,
         .LOAD_THIS_FIELD,
         .STORE_THIS_FIELD,
         .LOAD_FIELD,
         .STORE_FIELD,
         .LOAD_LOCAL_VAR,
         .STORE_LOCAL_VAR,
         .LOAD_UPVALUE,
         .STORE_UPVALUE:
        return 1
    case .CALL0,
         .CALL1,
         .CALL2,
         .CALL3,
         .CALL4,
         .CALL5,
         .CALL6,
         .CALL7,
         .CALL8,
         .CALL9,
         .CALL10,
         .CALL11,
         .CALL12,
         .CALL13,
         .CALL14,
         .CALL15,
         .CALL16,
         .LOAD_CONSTANT,
         .LOAD_MODULE_VAR,
         .STORE_MODULE_VAR,
         .LOOP,
         .JUMP,
         .JUMP_IF_FALSE,
         .AND,
         .OR,
         .INSTANCE_METHOD,
         .STATIC_METHOD:
        return 2
    case .SUPER0,
         .SUPER1,
         .SUPER2,
         .SUPER3,
         .SUPER4,
         .SUPER5,
         .SUPER6,
         .SUPER7,
         .SUPER8,
         .SUPER9,
         .SUPER10,
         .SUPER11,
         .SUPER12,
         .SUPER13,
         .SUPER14,
         .SUPER15,
         .SUPER16:
        return 4
    case .CREATE_CLOSURE:
        let fnIndex = Int(byteStream[ip + 1]) << 8 | Int(byteStream[ip + 2])
        guard let fn = constants[fnIndex].toFnObject() else {
            return 2 + 2
        }
        return 2 + fn.upvalueCount + 2
    case .none:
        return 0
    }
}
