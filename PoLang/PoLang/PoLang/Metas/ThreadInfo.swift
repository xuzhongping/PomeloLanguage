//
//  ThreadInfo.swift
//  PomeloLanguageContainer
//
//  Created by xuzhongping on 2020/5/23.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

public class ThreadInfo: NSObject {
    var stack: [Value]
    var stackCapacity: Int
    
    var esp: Index
    
    var frames: [CallFrameInfo]
    
    var caller: ThreadInfo?
    var errMsg: String?
    
    public init(closure: ClosureInfo) {
        self.stack = []
        self.stackCapacity = closure.fn.stackCapacity
        self.esp = 0
        self.frames = []
        let frame = CallFrameInfo(closure: closure, stackStart: 0)
        self.frames.append(frame)
    }
}

public class CallFrameInfo: NSObject {
    var ip: Index
    var closure: ClosureInfo
    var stackStart: Index
    init(closure: ClosureInfo, stackStart: Index) {
        self.ip = 0
        self.closure = closure
        self.stackStart = stackStart
    }
}
