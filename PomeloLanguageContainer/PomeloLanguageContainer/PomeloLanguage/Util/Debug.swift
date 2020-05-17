//
//  Debug.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/17.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public func PLDebugPrint(_ msg: String) {
    #if DEBUG
    print(msg)
    #endif
}
