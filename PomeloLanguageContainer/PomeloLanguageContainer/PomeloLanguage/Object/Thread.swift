//
//  Thread.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public let InitialFrameNum = 0

public class ThreadObject: NSObject, ObjectProtocol {
    public var header: Header
    var stack: [Value]
    var esp: Index
    var stackCapacity: UInt64
    
    var frames: [CallFrame]
    var usedFrameNum: Int
    var frameCapacity: Int
    
    var openUpvalue: [UpvalueObject]
    var caller: ThreadObject?
    var errorObject: Value?
    
    init(virtual: Virtual, closure: ClosureObject) {
        //TODO: 设置ThreadClass
        self.header = Header(virtual: virtual, type: .thread, cls: nil)
        frames = []
        frameCapacity = InitialFrameNum
        stack = []
        stackCapacity = closure.fn.maxStackSize + 1
        esp = 0
        usedFrameNum = 0
        openUpvalue = []
        super.init()
        resetThread(closure: closure)
    }
    
    public func prepareFrame(closure: ClosureObject, stack: inout [Value]) {
        let frame = frames[usedFrameNum + 1]
        frame.stack = stack
        frame.closure = closure
        //TODO:FIX
        frame.ip = 0
    }
    
    public func resetThread(closure: ClosureObject) {
        esp = 0
        openUpvalue = []
        caller = nil
        errorObject = nil
        prepareFrame(closure: closure, stack: &stack)
    }
}
