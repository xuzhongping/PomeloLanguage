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
        
    } else if unit.curLexParser.matchCurToken(expected: .while_) {
        compileWhileStatment(unit: unit)
        
    } else if unit.curLexParser.matchCurToken(expected: .for_) {
        compileForStatment(unit: unit)
        
    } else if unit.curLexParser.matchCurToken(expected: .return_) {
        compileReturn(unit: unit)
        
    } else if unit.curLexParser.matchCurToken(expected: .break_) {
        compileBreak(unit: unit)
        
    } else if unit.curLexParser.matchCurToken(expected: .continue_) {
        compileContinue(unit: unit)
        
    } else if unit.curLexParser.matchCurToken(expected: .leftBrace) {
        enterScope(unit: unit)
        compileBlock(unit: unit)
        leaveScope(unit: unit)
        
    } else {
        expression(unit: unit, rbp: .lowest)
        writeOpCode(unit: unit, code: .POP)
    }
}

/// 编译if语句
/// if (condition) {statement} [else {statement}]
public func compileIfStatment(unit: CompilerUnit) {
    // curToken为if后的(
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

/// 离开循环体的相关设置
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
                                            constants: unit.fn.constants,
                                            ip: index)
        }
    }
    unit.curLoop = loop.enclosingLoop
}

/// 编译while语句
public func compileWhileStatment(unit: CompilerUnit) {
    let loop = Loop()
    enterLoopSetting(unit: unit, loop: loop)
    
    unit.curLexParser.consumeCurToken(expected: .leftParen, message: "expect '(' befor condition!")
    expression(unit: unit, rbp: .lowest)
    unit.curLexParser.consumeCurToken(expected: .rightParen, message: "expect ')' after condition!")
    
    loop.exitIndex = emitInstrWithPlaceholder(unit: unit, opCode: .JUMP_IF_FALSE)
    compileLoopBody(unit: unit)
    leaveLoopSetting(unit: unit)
}

/// 获取ip所指向的操作码的操作数占用的字节数
func getBytesOfByteCode(byteStream: [Byte], constants: [AnyValue], ip: Index) -> Int {
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
            fatalError()
        }
        return 2 + fn.upvalueNum * 2
    case .none:
        fatalError()
    }
}

/// 编译return语句
public func compileReturn(unit: CompilerUnit) {
    let token = unit.curLexParser.curToken
    if token.type == .rightBrace {
        writeOpCode(unit: unit, code: .PUSH_NULL)
    } else {
        expression(unit: unit, rbp: .lowest)
    }
    writeOpCode(unit: unit, code: .RETURN)
}

/// 编译break语句
public func compileBreak(unit: CompilerUnit) {
    guard let loop = unit.curLoop else {
        fatalError("break should be used inside a loop!")
    }
    unit.destroyLocalVar(scopeDepth: loop.scopeDepth + 1)
    emitInstrWithPlaceholder(unit: unit, opCode: .END)
}

/// 编译continue语句
public func compileContinue(unit: CompilerUnit) {
    guard let loop = unit.curLoop else {
        fatalError("continue should be used inside a loop!")
    }
    unit.destroyLocalVar(scopeDepth: loop.scopeDepth + 1)
    // 销毁局部变量，回到循环开始处
    let loopBackOffset = unit.fn.byteStream.count - loop.condStartIndex + 2
    writeShortByteCode(unit: unit, code: .LOOP, operand: loopBackOffset)
}



/// 进入新的作用域
func enterScope(unit: CompilerUnit) {
    unit.scopeDepth += 1
}

/// 退出作用域
func leaveScope(unit: CompilerUnit) {
    if let _ = unit.enclosingUnit {
        let destroyNum = unit.destroyLocalVar(scopeDepth: unit.scopeDepth)
        unit.stackSlotNum -= destroyNum
    }
    unit.scopeDepth -= 1
}

public func compileForStatment(unit: CompilerUnit) {
    enterScope(unit: unit)
    unit.curLexParser.consumeCurToken(expected: .id, message: "expect variable after for!")
    
    guard let loopVarName = unit.curLexParser.preToken.value as? String else {
        fatalError()
    }
    
    unit.curLexParser.consumeCurToken(expected: .leftParen, message: "expect '(' befir sequence!")
    
    expression(unit: unit, rbp: .lowest)
    
    unit.curLexParser.consumeCurToken(expected: .rightParen, message: "expect ')' after sequence!")
    let seqSlot = unit.declareLocalVar(name: "seq ")
    
    writeOpCode(unit: unit, code: .PUSH_NULL)
    let iterSlot = unit.declareLocalVar(name: "iter ")
    
    let loop = Loop()
    enterLoopSetting(unit: unit, loop: loop)
    
    writeByteCode(unit: unit, code: .LOAD_LOCAL_VAR, operand: seqSlot)
    writeByteCode(unit: unit, code: .LOAD_LOCAL_VAR, operand: iterSlot)
    emitCall(unit: unit, argsNum: 1, name: "iterate(_)")
    
    writeByteCode(unit: unit, code: .STORE_LOCAL_VAR, operand: iterSlot)
    loop.exitIndex = emitInstrWithPlaceholder(unit: unit, opCode: .JUMP_IF_FALSE)
    
    writeByteCode(unit: unit, code: .LOAD_LOCAL_VAR, operand: seqSlot)
    writeByteCode(unit: unit, code: .LOAD_LOCAL_VAR, operand: iterSlot)
    emitCall(unit: unit, argsNum: 1, name: "iteratorValue(_)")

    enterScope(unit: unit)
    
    unit.declareLocalVar(name: loopVarName)
    compileLoopBody(unit: unit)
    
    leaveScope(unit: unit)
    
    leaveLoopSetting(unit: unit)
    leaveScope(unit: unit)
}
