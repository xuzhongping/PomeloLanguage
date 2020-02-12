//
//  PLLexParser.hpp
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/13.
//  Copyright © 2020 徐仲平. All rights reserved.
//

#ifndef PLLexParser_hpp
#define PLLexParser_hpp

#include <stdio.h>
#include <string>

#include "PLVM.hpp"

using namespace std;

typedef enum {
    PL_TOKEN_TYPE_UNKNOWN = 0,
    // 数据类型
    PL_TOKEN_TYPE_NUM,
    PL_TOKEN_TYPE_STRING,
    PL_TOKEN_TYPE_ID,       // 变量名
    PL_TOKEN_TYPE_INTERPOLATION,
    
    // 关键字
    PL_TOKEN_TYPE_VAR,
    PL_TOKEN_TYPE_FUN,
    PL_TOKEN_TYPE_IF,
    PL_TOKEN_TYPE_ELSE,
    PL_TOKEN_TYPE_TRUE,
    PL_TOKEN_TYPE_FALSE,
    PL_TOKEN_TYPE_WHILE,
    PL_TOKEN_TYPE_FOR,
    PL_TOKEN_TYPE_BREAK,
    PL_TOKEN_TYPE_CONTINUE,
    PL_TOKEN_TYPE_RETURN,
    PL_TOKEN_TYPE_NIL,
    
    // 类和模块
    PL_TOKEN_TYPE_CLASS,
    PL_TOKEN_TYPE_THIS,
    PL_TOKEN_TYPE_STATIC,
    PL_TOKEN_TYPE_IS,
    PL_TOKEN_TYPE_SUPER,
    PL_TOKEN_TYPE_IMPORT,
    
    // 分隔符
    PL_TOKEN_TYPE_COMMA,//,
    PL_TOKEN_TYPE_COLON,//:
    PL_TOKEN_TYPE_LEFT_PAREN,
    PL_TOKEN_TYPE_RIGHT_PAREN,
    PL_TOKEN_TYPE_LEFT_BRACKET,
    PL_TOKEN_TYPE_RIGHT_BRACKET,
    PL_TOKEN_TYPE_LEFT_BRACE,
    PL_TOKEN_TYPE_RIGHT_BRACE,
    PL_TOKEN_TYPE_DOT,
    PL_TOKEN_TYPE_DOT_DOT,
    
    // 双目运算符
    PL_TOKEN_TYPE_ADD,
    PL_TOKEN_TYPE_SUB,
    PL_TOKEN_TYPE_MUL,
    PL_TOKEN_TYPE_DIV,
    PL_TOKEN_TYPE_MOD,
    
    // 赋值运算符
    PL_TOKEN_TYPE_ASSIGN,
    
    // 位运算符
    PL_TOKEN_TYPE_BIT_AND,
    PL_TOKEN_TYPE_BIT_OR,
    PL_TOKEN_TYPE_BIT_NOT,
    PL_TOKEN_TYPE_BIT_SHIFT_LEFT,
    PL_TOKEN_TYPE_BIT_SHIFT_RIGHT,
    
    // 逻辑运算符
    PL_TOKEN_TYPE_LOGIC_AND,
    PL_TOKEN_TYPE_LOGIC_OR,
    PL_TOKEN_TYPE_LOGIC_NOT,
    
    // 关系运算符
    PL_TOKEN_TYPE_EQUAL,        // ==
    PL_TOKEN_TYPE_NOT_EQUAL,    // !=
    PL_TOKEN_TYPE_GREATE,       // >
    PL_TOKEN_TYPE_GREATE_EQUAL, // >=
    PL_TOKEN_TYPE_LESS,         // <
    PL_TOKEN_TYPE_LESS_EQUAL,   // <=
    
    PL_TOKEN_TYPE_QUESTION,     // ?
    
    PL_TOKEN_TYPE_EOF           // EOF
}PLTokenType;

template <class T>
class PLOptinal {
public:
    bool empty;
    T value;
    PLOptinal(bool empty) {
        this->empty = empty;
    }
    PLOptinal(T value) {
        this->value = value;
    }
};

class PLToken {
public:
    PLTokenType type;
    string code;
    uint32_t length;
    uint64_t line;
};

class PLLexParser {
    
public:
    string file;
    string sourceCode;
    uint64_t seek;
    PLToken *curToken;
    PLToken *preTolen;
    uint32_t expectationRightParenNum;
    PLVM VM;
    
    
    PLLexParser();
    PLLexParser(PLVM VM,string file,string sourceCode);
    
    PLOptinal<PLToken> getNextToken();
    bool matchNextToken(PLToken expected);
};

#endif /* PLLexParser_hpp */
