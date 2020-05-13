//
//  Variable.swift
//  PomeloLanguageContainer
//
//  Created by 徐仲平 on 2020/5/6.
//  Copyright © 2020 xuzhongping. All rights reserved.
//

import Cocoa

// MARK: 模块变量相关操作
extension ModuleObject {
    /// 声明模块变量
    public func declareModuleVar(virtual: Virtual, name: String) -> Index {
        guard name.count <= maxIdLength else {
            fatalError("length of identifier '\(name)' should be more than \(maxIdLength)")
        }
        
        moduleVarNames.append(name)
        moduleVarValues.append(AnyValue.placeholder)
        
        return moduleVarNames.lastIndex
    }
    
    /// 定义模块变量
    @discardableResult
    public func defineModuleVar(virtual: Virtual, name: String, value: AnyValue)  -> Index {
        guard name.count <= maxIdLength else {
            fatalError("length of identifier '\(name)' should be more than \(maxIdLength)")
        }
        
        if let nameIndex = moduleVarNames.firstIndex(of: name) {
            if moduleVarValues[nameIndex].isPlaceholder() {
                moduleVarValues[nameIndex] = value
                return nameIndex
            }
            return Index.repeatDefine
        }
        
        moduleVarNames.append(name)
        moduleVarValues.append(value)
        return moduleVarNames.lastIndex
    }
    
}



// MARK: 局部变量相关操作
extension CompilerUnit {
    /// 声明局部变量
    @discardableResult
    private func addLocalVar(name: String) -> Index {
        let localVar = LocalVar(name: name)
        localVar.scopeDepth = scopeDepth
        localVar.isUpvalue = false
        localVars.append(localVar)
        return localVars.lastIndex
    }
    
    /// 声明局部变量并检查是否重定义
    public func declareLocalVar(name: String) -> Index {
        guard localVars.count <= maxLocalVarNum else {
           fatalError("the max length of local variable of one scope is \(maxLocalVarNum)")
        }
       
        for localVar in localVars.reversed() {
            // 只找自己作用域内的
            guard localVar.scopeDepth >= scopeDepth else {
                break
            }
            
            // 检查重复定义
            guard localVar.name != name else {
                fatalError("identifier \(name) redefinition!")
            }
        }
        return addLocalVar(name: name)
    }
    
    /// 查找局部变量
    /// 从内层向外层查
    public func findLocalVar(name: String) -> Index {
        return localVars.reversed().firstIndex { (localVar) -> Bool in
            localVar.name == name
            } ?? Index.notFound
    }
    
    /// 销毁作用域scopeDepth之内的局部变量
    @discardableResult
    public func destroyLocalVar(scopeDepth: Int) -> Int {
        guard self.scopeDepth > ScopeDepth.module else {
            fatalError("module scope can`t exit!")
        }
        
        var localIndex = self.localVars.lastIndex
        while localIndex >= 0 && self.localVars[localIndex].scopeDepth >= scopeDepth {
            if self.localVars[localIndex].isUpvalue {
                writeByte(unit: self, byte: OP_CODE.CLOSE_UPVALUE.rawValue)
            } else {
                writeByte(unit: self, byte: OP_CODE.POP.rawValue)
            }
            localIndex -= 1
        }
        return self.localVars.count - 1 - localIndex
    }
    
}

// MARK: upvalue相关操作
extension CompilerUnit {
    /// 添加upvalue
    public func addUpvalue(isEnclosingLocalVar: Bool, index: Index) -> Index {
        let index = upvalues.firstIndex { (upvalue) -> Bool in
            
            upvalue.index == index && upvalue.isEnclosingLocalVar == isEnclosingLocalVar
            
            } ?? Index.notFound
        if index != Index.notFound {
            return index
        }
        upvalues.append(Upvalue(index: index, isEnclosingLocalVar: isEnclosingLocalVar))
        return upvalues.lastIndex
    }
    
    /// 查找名为name的upvalue添加到upvalues中，返回其索引
    public func findUpvalue(name: String) -> Index {
        guard let enclosingUnit = enclosingUnit else {
            return Index.notFound
        }
        
        if !name.contains(" ") && enclosingUnit.enclosingClassBK != nil {
            return Index.notFound
        }
        
        let localIndex = enclosingUnit.findLocalVar(name: name)
        if localIndex != Index.notFound {
            enclosingUnit.localVars[localIndex].isUpvalue = true
            return addUpvalue(isEnclosingLocalVar: true, index: localIndex)
        }
        
        let upvalueIndex = enclosingUnit.findUpvalue(name: name)
        if upvalueIndex != Index.notFound {
            return addUpvalue(isEnclosingLocalVar: false, index: upvalueIndex)
        }
        return Index.notFound
    }
}

// MARK: 模块变量和局部变量的封装接口
extension CompilerUnit {
    /// 根据作用域声明变量(模块变量或局部变量)
    @discardableResult
    public func declareVariable(name: String) -> Int {
        if scopeDepth == ScopeDepth.module {
            let index = curLexParser.curModule.declareModuleVar(virtual: curLexParser.virtual, name: name)
            if index == Index.repeatDefine {
                fatalError("identifier \(name) redefinition!")
            }
            return index
        }
        return declareLocalVar(name: name)
    }
    
    public func emitDefineVariable(index: Index) {
        if scopeDepth == ScopeDepth.module {
            writeShortByteCode(unit: self, code: .STORE_MODULE_VAR, operand: index)
            writeOpCode(unit: self, code: .POP)
        }
    }
}


// MARK: Variable相关
extension CompilerUnit {
    
    /// 生成加载变量到栈的指令
    public func emitLoadVariable(variable: Variable) {
        switch variable.type {
        case .local:
            writeByteCode(unit: self, code: OP_CODE.LOAD_LOCAL_VAR, operand: variable.index)
        case .upvalue:
            writeByteCode(unit: self, code: OP_CODE.LOAD_UPVALUE, operand: variable.index)
        case .module:
            writeShortByteCode(unit: self, code: OP_CODE.LOAD_MODULE_VAR, operand: variable.index)
        }
    }

    /// 生成从栈顶弹出数据到变量中存储的指令
    public func emitStoreVariable(variable: Variable) {
        switch variable.type {
        case .local:
            writeByteCode(unit: self, code: OP_CODE.STORE_LOCAL_VAR, operand: variable.index)
        case .upvalue:
            writeByteCode(unit: self, code: OP_CODE.STORE_UPVALUE, operand: variable.index)
        case .module:
            writeShortByteCode(unit: self, code: OP_CODE.STORE_MODULE_VAR, operand: variable.index)
        }
    }
    
    /// 从局部变量和upvalue中查找符号name
    public func findVariable(name: String) -> Variable? {
        var index = findLocalVar(name: name)
        if index != Index.notFound {
            return Variable(type: .local, index: index)
        }
        index = findUpvalue(name: name)
        if index != Index.notFound {
            return Variable(type: .upvalue, index: index)
        }
        return nil
    }
}

// MARK: 常量相关
extension CompilerUnit {
    /// 定义常量
    public func defineConstant(constant: AnyValue) -> Index {
        fn.constants.append(constant)
        return fn.constants.lastIndex
    }
    
    /// 生成加载常量的指令
    public func emitLoadConstant(constantIndex: Index) {
        writeShortByteCode(unit: self, code: .LOAD_CONSTANT, operand: constantIndex)
    }
}
