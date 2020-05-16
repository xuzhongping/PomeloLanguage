//
//  LexParserTest.swift
//  PomeloLanguageContainerTests
//
//  Created by 徐仲平 on 2020/5/16.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import XCTest
@testable import PomeloLanguageContainer

class LexParserTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testLexParse() {
        let code = Loader.loadCoreModule()
        let lexParser = LexParser(virtual: Virtual(), moduleName: "core", module: ModuleObject(name: "core", virtual: Virtual()), file: nil, code: code)
        lexParser.nextToken()
        while true {
            guard lexParser.curToken.type != .eof else {
                print("end")
                break
            }
            print("\(lexParser.curToken.type):\(String(describing: lexParser.curToken.value))")
            lexParser.nextToken()
        }
    }

}
