//
//  PLVM.hpp
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/12.
//  Copyright © 2020 徐仲平. All rights reserved.
//

#ifndef PLVM_hpp
#define PLVM_hpp

#include <stdio.h>

class PLVM {
    
public:
    u_int64_t allocatedBytes;
    PLVM();
    ~PLVM();
};

#endif /* PLVM_hpp */
