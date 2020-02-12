//
//  PoLangLexParser.cpp
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/2/13.
//  Copyright © 2020 徐仲平. All rights reserved.
//

#include "PLLexParser.hpp"

PLLexParser::PLLexParser(PLVM VM,string file,string sourceCode){
    this->VM = VM;
    this->file = file;
    this->sourceCode = sourceCode;
}

PLLexParser::PLLexParser(){}


PLOptinal<PLToken> PLLexParser::getNextToken() {
    return PLOptinal<PLToken>(true);
}

bool PLLexParser::matchNextToken(PLToken expected) {
    return false;
}
