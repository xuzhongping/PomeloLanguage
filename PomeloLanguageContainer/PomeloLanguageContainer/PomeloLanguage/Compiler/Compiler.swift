//
//  Compiler.swift
//  PomeloLanguage
//
//  Created by 徐仲平 on 2020/3/14.
//  Copyright © 2020 徐仲平. All rights reserved.
//

import Cocoa

public let maxLocalVarNum = 128
public let maxUpvalueNum = 128
public let maxIdLength = 128
public let maxMethodNameLength = maxIdLength
public let maxArgNum = 16
public let maxSignLenth = maxMethodNameLength + maxArgNum * 2 + 1
public let maxFieldNum = 128

public class Upvalue {
    var isEnclosingLocalVar: Bool
    var index: Index
    init(index: Index, isEnclosingLocalVar: Bool) {
        self.index = index
        self.isEnclosingLocalVar = isEnclosingLocalVar
    }
}

public class LocalVar {
    public var name: String?
    public var scopeDepth: Int
    public var isUpvalue: Bool
    init(name: String?) {
        self.name = name
        self.scopeDepth = -1
        self.isUpvalue = false
    }
}



class Loop {
    var condStartIndex: Index
    var bodyStartIndex: Index
    var scopeDepth: Int
    var exitIndex: Index
    var enclosingLoop: Loop?
    init() {
        condStartIndex = 0
        bodyStartIndex = 0
        scopeDepth = 0
        exitIndex = 0
    }
}

/// 用于记录类编译时的信息
public class ClassBookKeep {
    var name: String
    var fields: [(name: String, value: AnyValue)]
    var inStatic: Bool
    var instanceMethods: [Index]
    var staticMethods: [Index]
    var signature: Signature?
        
    init(name: String) {
        self.name = name
        self.fields = []
        self.instanceMethods = []
        self.staticMethods = []
        self.inStatic = false
    }
}



public class CompilerUnit: NSObject {
    
    /// 当前编译函数
    var fn: FnObject
    
    /// 当前作用域的局部变量
    var localVars: [LocalVar]
    
    /// 记录本层函数所引用的upvalue
    var upvalues: [Upvalue]
    
    /// 当前正在编译的代码所处作用域
    var scopeDepth: Int
    
    /// 当前使用的slot个数
    var stackSlotNum: Int
    
    /// 当前正在编译的循环层
    var curLoop: Loop?
    
    /// 当前正在编译的类的编译信息
    var enclosingClassBK: ClassBookKeep?
    
    /// 包含此编译单元的编译单元，直接外层
    var enclosingUnit: CompilerUnit?
    
    /// 当前词法解析器
    var curLexParser: LexParser
    
    init(lexParser: LexParser, enclosingUnit: CompilerUnit?, isMethod: Bool) {
        self.curLexParser = lexParser
        self.enclosingUnit = enclosingUnit
        self.enclosingClassBK = nil
        self.stackSlotNum = 1
        self.localVars = []
        self.upvalues = []
        
        // 有外层单元，这里是局部作用域
        if let _ = enclosingUnit {
            if isMethod {
                let thisLocalVar = LocalVar(name: "this")
                self.localVars.append(thisLocalVar)
            } else {
                let thisLocalVar = LocalVar(name: nil)
                self.localVars.append(thisLocalVar)
            }
            
            localVars.first?.scopeDepth = -1
            scopeDepth = 0
        } else {
            /// 没有外层编译单元，说明是模块作用域
            /// 模块作用域为-1
            scopeDepth = -1
        }
        self.fn = FnObject(virtual: curLexParser.virtual,
                           module: curLexParser.curModule,
                           maxStackSize: localVars.count)
        
        super.init()
        
        lexParser.curCompileUnit = self
    }
}


// MARK: 变量操作相关
extension CompilerUnit {
   
    public func compileProgram() {
        
    }
    
    /// 添加局部变量
    @discardableResult
    public func addLocalVar(name: String) -> Int {
        let localVar = LocalVar(name: name)
        localVar.scopeDepth = scopeDepth
        localVar.isUpvalue = false
        localVars.append(localVar)
        return localVars.count - 1
    }
    
    /// 声明局部变量
    public func declareLocalVar(name: String) -> Int {
        guard localVars.count >= maxArgNum else {
           fatalError()
        }
       
        for localVar in localVars.reversed() {
           guard localVar.scopeDepth >= scopeDepth else { break }
           guard localVar.name != name else { fatalError() }
        }
        return addLocalVar(name: name)
    }
   
    @discardableResult
    public func declareVariable(name: String) -> Int {
        if scopeDepth == -1 {
            let index = curLexParser.curModule.defineVar(virtual: curLexParser.virtual,
                                                             name: name,
                                                             value: AnyValue(value: nil))
            return index
        }
        return declareLocalVar(name: name)
    }
    
    public func defineVariable(index: Int) {
        guard scopeDepth != -1 else {
            return
        }
        writeByteCode(unit: self, code: OP_CODE.STORE_MODULE_VAR, operand: index)
        writeOpCode(unit: self, code: OP_CODE.POP)
    }
    
    /// 添加常量并返回索引
    public func addConstant(constant: AnyValue) -> Int {
        fn.constants.append(constant)
        return fn.constants.count - 1
    }
    
    public func getEnclosingClassBKUnit() -> CompilerUnit? {
        var unit: CompilerUnit? = self
        while unit != nil {
            if unit?.enclosingClassBK != nil {
                return unit
            }
            unit = unit?.enclosingUnit
        }
        return nil
    }
    
    public func getEnclosingClassBK() -> ClassBookKeep? {
        if let unit = getEnclosingClassBKUnit() {
            return unit.enclosingClassBK
        }
        return nil
    }
    
    /// 查找局部变量
    public func findLocalVar(name: String) -> Int {
        return localVars.firstIndex { (localVar) -> Bool in localVar.name == name } ?? -1
    }
    
    /// 添加upvalue
    public func addUpvalue(isEnclosingLocalVar: Bool, index: Index) -> Int {
        let index = upvalues.firstIndex { (upvalue) -> Bool in
            upvalue.index == index && upvalue.isEnclosingLocalVar == isEnclosingLocalVar
        } ?? -1
        if index >= 0 {
            return index
        }
        upvalues.append(Upvalue(index: index, isEnclosingLocalVar: isEnclosingLocalVar))
        return upvalues.count - 1
    }
    
    /// 查找名为name的upvalue添加到upvalues中，返回其索引
    public func findUpvalue(name: String) -> Int {
        guard let enclosingUnit = enclosingUnit else { return IndexNotFound }
        if !name.contains(" ") && enclosingUnit.enclosingClassBK != nil {
            return IndexNotFound
        }
        let localIndex = enclosingUnit.findLocalVar(name: name)
        if localIndex >= 0 {
            return addUpvalue(isEnclosingLocalVar: true, index: localIndex)
        }
        let upvalueIndex = enclosingUnit.findUpvalue(name: name)
        if upvalueIndex >= 0 {
            return addUpvalue(isEnclosingLocalVar: false, index: upvalueIndex)
        }
        return IndexNotFound
    }
    
    /// 从局部变量和upvalue中查找符号name
    public func findVarFromLocalOrUpvalue(name: String) -> Variable? {
        var index = findLocalVar(name: name)
        if index != IndexNotFound {
            return Variable(type: .local, index: index)
        }
        index = findUpvalue(name: name)
        if index != IndexNotFound {
            return Variable(type: .upvalue, index: index)
        }
        return nil
    }
}

/// 用于内部变量查找
public class Variable: NSObject {
    public enum ScopeType {
        case invalid
        case local
        case upvalue
        case module
    }
    var type: ScopeType
    var index: Index
    init(type: ScopeType, index: Index) {
        self.type = type
        self.index = index
    }
}





/// 语法分析核心
public func expression(unit: CompilerUnit, rbp: SymbolBindRule.BindPower) {
    guard let curToken = unit.curLexParser.curToken else {
        fatalError()
    }
    guard let nud = SymbolBindRule.rulues[curToken.type]?.nud else {
        fatalError()
    }
    unit.curLexParser.nextToken()

    let assign = rbp.rawValue < SymbolBindRule.BindPower.assign.rawValue
    nud(unit,assign)

    while true {
        guard let token = unit.curLexParser.curToken else {
            break
        }
        guard let lbp = SymbolBindRule.rulues[token.type]?.lbp else {
            break
        }
        guard rbp.rawValue < lbp.rawValue else {
            break
        }
        guard let led = SymbolBindRule.rulues[token.type]?.led else {
            break
        }
        unit.curLexParser.nextToken()
        led(unit, assign)
    }
}

