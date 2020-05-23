//
//  Virtual.swift
//  PoLang
//
//  Created by xuzhongping on 2020/5/23.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class Virtual: NSObject {
    
    private var context: CompileContext
    
    init(context: CompileContext) {
        self.context = context
    }
}
