//
//  Thread.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public let InitialFrameNum = 0

public class ThreadObject: BaseObject {
    var stack: [AnyValue]
    var esp: Index
    var stackCapacity: Int
    
    var frames: [CallFrame]
    var usedFrameNum: Int {
        frames.count
    }
    var frameCapacity: Int
    
    var openUpvalues: [UpvalueObject]
    var caller: ThreadObject?
    var errorObject: AnyValue?
    
    init(virtual: Virtual, closure: ClosureObject) {
        frames = []
        frameCapacity = InitialFrameNum
        stack = []
        stackCapacity = closure.fn.maxStackSize + 1
        esp = 0
        openUpvalues = []
        super.init(virtual: virtual, type: .thread, cls: nil)
        resetThread(closure: closure)
    }
    
    public func prepareFrame(closure: ClosureObject, stackIndex: Int) {
        let frame = frames[usedFrameNum + 1]
        frame.stackStart = stackIndex
        frame.closure = closure
        //TODO:FIX
        frame.ip = 0
    }
    
    public func resetThread(closure: ClosureObject) {
        esp = 0
        openUpvalues = []
        caller = nil
        errorObject = nil
        prepareFrame(closure: closure, stackIndex: 0)
    }
}
