//
//  Thread.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public let InitialFrameNum = 4

/// 编译时和运行时结构
public class ThreadObject: BaseObject {
    var stack: [AnyValue]
    var stackCapacity: Int
    
    var esp: Index
    
    var frames: [CallFrame]
    var frameCapacity: Int
    var usedFrameNum: Int {
        frames.count
    }
    
    var openUpvalues: [UpvalueObject]
    var caller: ThreadObject?
    var errorObject: AnyValue?
    
    init(virtual: Virtual, closure: ClosureObject) {
        stack = []
        stackCapacity = closure.fn.maxStackSize + 1
        
        esp = 0
        frames = []
        frameCapacity = InitialFrameNum
        
        openUpvalues = []
        super.init(virtual: virtual, type: .thread, cls: nil)
    
        resetThread(closure: closure)
    }
    
    /// 为函数准备栈帧运行
    public func prepareFrame(closure: ClosureObject, stackIndex: Index) {
        guard frameCapacity >= usedFrameNum else {
            fatalError("frame not enough!")
        }
        // ip 位于 closure.fn.byteStream中的第0个字节
        let frame = CallFrame(closure: closure, stackStart: stackIndex, ip: 0)
        frames.append(frame)
    }
    
    /// 重置thread
    public func resetThread(closure: ClosureObject) {
        esp = 0
        openUpvalues = []
        caller = nil
        errorObject = nil
        prepareFrame(closure: closure, stackIndex: 0)
    }
}
