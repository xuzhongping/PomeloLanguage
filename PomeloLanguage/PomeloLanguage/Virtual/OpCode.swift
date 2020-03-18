//
//  OpCode.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/16.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public struct OP_CODE {
    let code: OP_CODE_ENUM
    let effect: Int
}

public enum OP_CODE_ENUM: Byte {
    case LOAD_CONSTANT = 0
    case PUSH_NULL
    case PUSH_FALSE
    case PUSH_TRUE
    case LOAD_LOCAL_VAR
    case STORE_LOCAL_VAR
    case LOAD_UPVALUE
    case STORE_UPVALUE
    case LOAD_MODULE_VAR
    case STORE_MODULE_VAR
    case LOAD_THIS_FIELD
    case STORE_THIS_FIELD
    case LOAD_FIELD
    case STORE_FIELD
    case POP
    case CALL0
    case CALL1
    case CALL2
    case CALL3
    case CALL4
    case CALL5
    case CALL6
    case CALL7
    case CALL8
    case CALL9
    case CALL10
    case CALL11
    case CALL12
    case CALL13
    case CALL14
    case CALL15
    case CALL16
    case SUPER0
    case SUPER1
    case SUPER2
    case SUPER3
    case SUPER4
    case SUPER5
    case SUPER6
    case SUPER7
    case SUPER8
    case SUPER9
    case SUPER10
    case SUPER11
    case SUPER12
    case SUPER13
    case SUPER14
    case SUPER15
    case SUPER16
    case JUMP
    case LOOP
    case JUMP_IF_FALSE
    case AND
    case OR
    case CLOSE_UPVALUE
    case RETURN
    case CREATE_CLOSURE
    case CONSTRUCT
    case CREATE_CLASS
    case INSTANCE_METHOD
    case STATIC_METHOD
    case END
}


public let OP_CODE_LIST: Buffer<OP_CODE> = [
    OP_CODE(code: .LOAD_CONSTANT, effect: 1),
    OP_CODE(code: .PUSH_NULL, effect: 1),
    OP_CODE(code: .PUSH_FALSE, effect: 1),
    OP_CODE(code: .PUSH_TRUE, effect: 1),
    OP_CODE(code: .LOAD_LOCAL_VAR, effect: 1),
    OP_CODE(code: .STORE_LOCAL_VAR, effect: 0),
    OP_CODE(code: .LOAD_UPVALUE, effect: 1),
    OP_CODE(code: .STORE_UPVALUE, effect: 0),
    OP_CODE(code: .LOAD_MODULE_VAR, effect: 1),
    OP_CODE(code: .STORE_MODULE_VAR, effect: 0),
    OP_CODE(code: .LOAD_THIS_FIELD, effect: 1),
    OP_CODE(code: .STORE_THIS_FIELD, effect: 0),
    OP_CODE(code: .LOAD_FIELD, effect: 0),
    OP_CODE(code: .STORE_FIELD, effect: -1),
    
    OP_CODE(code: .POP, effect: -1),
    OP_CODE(code: .CALL0, effect: 0),
    OP_CODE(code: .CALL1, effect: -1),
    OP_CODE(code: .CALL2, effect: -2),
    OP_CODE(code: .CALL3, effect: -3),
    OP_CODE(code: .CALL4, effect: -4),
    OP_CODE(code: .CALL5, effect: -5),
    OP_CODE(code: .CALL6, effect: -6),
    OP_CODE(code: .CALL7, effect: -7),
    OP_CODE(code: .CALL8, effect: -8),
    OP_CODE(code: .CALL9, effect: -9),
    OP_CODE(code: .CALL10, effect: -10),
    OP_CODE(code: .CALL11, effect: -11),
    OP_CODE(code: .CALL12, effect: -12),
    OP_CODE(code: .CALL13, effect: -13),
    OP_CODE(code: .CALL14, effect: -14),
    OP_CODE(code: .CALL15, effect: -15),
    OP_CODE(code: .CALL16, effect: -16),
    
    OP_CODE(code: .SUPER0, effect: 0),
    OP_CODE(code: .SUPER1, effect: -1),
    OP_CODE(code: .SUPER2, effect: -2),
    OP_CODE(code: .SUPER3, effect: -3),
    OP_CODE(code: .SUPER4, effect: -4),
    OP_CODE(code: .SUPER5, effect: -5),
    OP_CODE(code: .SUPER6, effect: -6),
    OP_CODE(code: .SUPER7, effect: -7),
    OP_CODE(code: .SUPER8, effect: -8),
    OP_CODE(code: .SUPER9, effect: -9),
    OP_CODE(code: .SUPER10, effect: 10),
    OP_CODE(code: .SUPER11, effect: -11),
    OP_CODE(code: .SUPER12, effect: -12),
    OP_CODE(code: .SUPER13, effect: -13),
    OP_CODE(code: .SUPER14, effect: -14),
    OP_CODE(code: .SUPER15, effect: -15),
    OP_CODE(code: .SUPER16, effect: -16),
    
    OP_CODE(code: .JUMP, effect: 0),
    OP_CODE(code: .LOOP, effect: 0),
    OP_CODE(code: .JUMP_IF_FALSE, effect: -1),
    OP_CODE(code: .AND, effect: -1),
    OP_CODE(code: .OR, effect: -1),
    OP_CODE(code: .CLOSE_UPVALUE, effect: -1),
    OP_CODE(code: .RETURN, effect: 0),
    OP_CODE(code: .CREATE_CLOSURE, effect: 1),
    OP_CODE(code: .CONSTRUCT, effect: 0),
    OP_CODE(code: .CREATE_CLASS, effect: -1),
    OP_CODE(code: .INSTANCE_METHOD, effect: -2),
    OP_CODE(code: .STATIC_METHOD, effect: -2),
    OP_CODE(code: .END, effect: 0)
]


