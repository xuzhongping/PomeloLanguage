//
//  PoLangObject.hpp
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/13.
//  Copyright © 2020 徐仲平. All rights reserved.
//

#ifndef PoLangObject_hpp
#define PoLangObject_hpp

#include <stdio.h>

// 对象类型
typedef enum {
    PL_OT_CLASS = 0,
    PL_OT_LIST,
    PL_OT_MAP,
    PL_OT_MODULE,
    PL_OT_RANGE,
    PL_OT_STRING,
    PL_OT_UPVALUE,
    PL_OT_FUNCTION,
    PL_OT_CLOSURE,
    PL_OT_INSTANCE,
    PL_OT_THREAD,
}PLObjectType;

typedef enum {
    PL_VT_UNDEFINED = 0,
    PL_VT_NULL,
    PL_VT_FALSE,
    PL_VT_TRUE,
    PL_VT_NUM,
    PL_VT_OBJ
}PLValueType;

class PLObjectHeader {
    
public:
    PLObjectType type;
    bool isDark;
    PLObjectHeader *next;
};

class PLValue {
public:
    PLValueType type;
    union {
        double num;
        PLObjectHeader objHeader;
    };
};


#endif /* PoLangObject_hpp */
