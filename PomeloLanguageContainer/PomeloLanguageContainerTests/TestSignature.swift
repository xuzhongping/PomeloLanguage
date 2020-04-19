//
//  TestSignature.swift
//  PomeloLanguageContainerTests
//
//  Created by xuzhongping on 2020/3/26.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import XCTest
@testable import PomeloLanguageContainer

class TestSignature: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testToString() {
        let signature = Signature(type: .getter, name: "", argNum: 2)
        print(signature.toString())
        
    }

}
