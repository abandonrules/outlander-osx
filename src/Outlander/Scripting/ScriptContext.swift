//
//  ScriptContext.swift
//  Scripter
//
//  Created by Joseph McBride on 11/17/14.
//  Copyright (c) 2014 Joe McBride. All rights reserved.
//

import Foundation
import OysterKit

public class Stack<T>
{
    var stack:[T] = []
    
    public func push(item:T) {
        stack.append(item)
    }
    
    public func pop() -> T {
        return stack.removeLast()
    }
    
    public func lastItem() -> T? {
        return stack.last
    }
    
    public func hasItems() -> Bool {
        return stack.count > 0
    }
}

public class ScriptContext {
    var tree:[Token]
    var marker:TokenSequence
    var results:Array<Token>
    var current:GeneratorOf<Token>
    
    private let varReplacer:SimpleVarReplacer
    private var variables:[String:String] = [:]
    
    private var globalVars:(()->[String:String])?
    
    init(_ tree:[Token], globalVars:(()->[String:String])?, params:[String]) {
        self.tree = tree
        self.marker = TokenSequence()
        self.marker.tree = self.tree
        self.current = self.marker.generate()
        self.results = Array<Token>()
        self.varReplacer = SimpleVarReplacer()
        self.globalVars = globalVars
        
        variables["0"] = " ".join(params)
        
        for (index, param) in enumerate(params) {
            variables["\(index+1)"] = param
        }
    }
    
    public func execute() {
//        seq.currentIdx = 1
        
        for t in marker {
            evalToken(t)
        }
    }
    
    public func setVariable(identifier:String, value:String) {
        self.variables[identifier] = value
    }
    
    public func gotoLabel(label:String) -> Bool {
        self.marker.currentIdx = -1
        var found = false
        
        var trimmed = label.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        while let token = self.current.next() {
            if let labelToken = token as? LabelToken where labelToken.characters == trimmed {
                //println("Found: \(labelToken.characters) at \(self.marker.currentIdx)")
                found = true
                break
            }
        }
        
        self.marker.currentIdx -= 1
        return found
    }
    
    public func roundtime() -> Double? {
        return self.globalVars?()["roundtime"]?.toDouble()
    }
    
    public func next() -> Token? {
        var nextToken = self.current.next()
        
        if let token = nextToken {
            evalToken(token)
        }
        
        return nextToken
    }
    
    public func evalToken(token:Token) {
        if(token is BranchToken) {
            var branchToken = token as! BranchToken
            if(!evalIf(branchToken)) {
                self.marker.branchStack.pop()
            }
        }

        if !(token.name == "whitespace") {
            self.results.append(token)
        }
    }
    
    private func evalIf(token:BranchToken) -> Bool {
        // TODO: handle if_1
        // token.argumentCheck
        
        var evaluator = ExpressionEvaluator()
        var (result, info) = evaluator.eval(token.expression, self.simplify)
        token.lastResult = info
        return result
    }
    
    public func simplify(data:String) -> String {
        var text = data
        
        if text.hasPrefix("%") {
            text = varReplacer.eval(text, vars: self.variables)
        }
        
        if text.hasPrefix("$") && self.globalVars != nil {
            text = varReplacer.eval(text, vars: self.globalVars!())
        }
        
        return text
    }
    
    public func simplify(tokens:Array<Token>) -> String {
        var text = ""
        
        for t in tokens {
            text += t.characters
        }
        
        return self.simplify(text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
    }
    
    public func simplifyEach(tokens:Array<Token>) -> String {
        var result = ""
        
        for t in tokens {
            if t is WhiteSpaceToken {
                result += t.characters
            }
            else {
                result += self.simplify(t.characters)
            }
        }
        
        return result
    }
}

class TokenSequence : SequenceType {
    var tree:[Token]
    var currentIdx:Int
    var branchStack:Stack<GeneratorOf<Token>>
    
    init () {
        currentIdx = -1
        tree = [Token]()
        branchStack = Stack<GeneratorOf<Token>>()
    }
    
    func generate() -> GeneratorOf<Token> {
        return GeneratorOf<Token>({
            if var b = self.branchStack.lastItem() {
                if let next = b.next() {
                    return next
                } else {
                    self.branchStack.pop()
                }
            }
            
            var bodyToken = self.getNext()
            if let nextToken = bodyToken {
                if let branchToken = nextToken as? BranchToken {
                    var seq = BranchTokenSequence(branchToken).generate()
                    self.branchStack.push(seq)
                }
                return nextToken
            } else {
                return .None
            }
        })
    }
    
    func getNext() -> Token? {
        var token:Token?
        self.currentIdx++
        if(self.currentIdx > -1 && self.currentIdx < self.tree.count) {
            token = self.tree[self.currentIdx]
        }
        
        if let next = token {
            if next.name == "whitespace" {
                token = getNext()
            }
        }
        
        return token
    }
}

class BranchTokenSequence : SequenceType {
    var token:BranchToken
    var branchStack:Stack<GeneratorOf<Token>>
    var currentIndex:Int
    
    init (_ token:BranchToken) {
        self.token = token
        currentIndex = -1
        branchStack = Stack<GeneratorOf<Token>>()
    }
    
    func generate() -> GeneratorOf<Token> {
        return GeneratorOf<Token>({
            if var b = self.branchStack.lastItem() {
                if let next = b.next() {
                    return next
                } else {
                    self.branchStack.pop()
                }
            }
            
            var bodyToken = self.getNext()
            if let nextToken = bodyToken {
                if let branchToken = nextToken as? BranchToken {
                    var seq = BranchTokenSequence(branchToken).generate()
                    self.branchStack.push(seq)
                    return branchToken
                }
                
                return nextToken
            } else {
                return .None
            }
        })
    }
    
    func getNext() -> Token? {
        var token:Token?
        self.currentIndex++
        if(self.currentIndex < self.token.body.count) {
            token = self.token.body[self.currentIndex]
        }
        
        if let next = token as? WhiteSpaceToken {
            token = getNext()
        }
        
        return token
    }
}