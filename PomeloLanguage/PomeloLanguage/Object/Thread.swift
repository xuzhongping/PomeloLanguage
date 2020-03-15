//
//  Thread.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public let InitialFrameNum = 0

public class ThreadObject: ObjectProtocol {
    public var header: Header
    var stack: Int
    var esp: Int
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
        stack = 0
        stackCapacity = closure.fn.maxStackSize + 1
        esp = 0
        usedFrameNum = 0
        openUpvalue = []
        resetThread(closure: closure)
    }
    
    public func prepareFrame(closure: ClosureObject, stack: Int) {
        let frame = frames[usedFrameNum + 1]
        frame.stack = stack
        frame.closure = closure
        //TODO:FIX
        frame.ip = uint64(closure.fn.instrStream.first!)
    }
    
    public func resetThread(closure: ClosureObject) {
        esp = stack
        openUpvalue = []
        caller = nil
        errorObject = nil
        prepareFrame(closure: closure, stack: stack)
    }
}
