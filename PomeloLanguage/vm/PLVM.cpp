//
//  PLVM.cpp
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/12.
//  Copyright © 2020 徐仲平. All rights reserved.
//

#include "PLVM.hpp"
#include <iostream>

using namespace std;

PLVM::PLVM() {
    this->allocatedBytes = 0;
}

PLVM::~PLVM() {
    cout << "PLVM instance is destroy";
}
