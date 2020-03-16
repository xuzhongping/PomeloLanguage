//
//  OpCode.swift
//  PomeloLanguage
//
//  Created by xuzhongping on 2020/3/16.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

enum OP_CODE {
    case LOAD_CONSTANT
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
