//
//  main.cpp
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/11.
//  Copyright © 2020 徐仲平. All rights reserved.
//

#include <iostream>

#include "PLLexParser.hpp"

int main(int argc, const char * argv[]) {
    // insert code here...
    std::cout << "Hello, World!\n";
    
    PLLexParser *lexParser = new PLLexParser;
    if (lexParser->getNextToken().empty) {
        std::cout << "empty";
    }
    
    return 0;
}
