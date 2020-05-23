//
//  Virtual.swift
//  PoLang
//
//  Created by xuzhongping on 2020/5/23.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class Virtual: NSObject {
    
    enum Result {
        case success
        case fail
    }
    
    public var context: RuntimeContext
    
    override init() {
        self.context = RuntimeContext()
    }
    
    @discardableResult
    func execute(context: RuntimeContext, fn: FnInfo) -> Result {
        return .success
    }
}
