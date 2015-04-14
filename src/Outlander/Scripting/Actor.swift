//
//  Actor.swift
//  Scripter
//
//  Created by Joseph McBride on 11/17/14.
//  Copyright (c) 2014 Joe McBride. All rights reserved.
//

import Foundation
import OysterKit

public class Message {
    var name:String
    
    public init(_ name:String) {
        self.name = name
    }

    public var description : String {
        return self.name;
    }
}

public class UnknownMessage : Message {
}

public class ScriptInfoMessage : Message {
    public override init(_ msg:String) {
        super.init(msg)
    }
}

public class OperationComplete : Message {
    var operation:String
    var msg:String
    
    public init(_ operation:String, msg:String) {
        self.operation = operation
        self.msg = msg
        super.init("operation-complete")
    }
    
    public override var description : String {
        return "\(self.name) - \(self.operation)";
    }
}

public class DebugLevelMessage : Message {
    var level:ScriptLogLevel
    
    public init(_ level:Int) {
        self.level = ScriptLogLevel(rawValue: level) ?? ScriptLogLevel.None
        super.init("debug-level")
    }
}

public class PauseMessage : Message {
    var seconds:Double = 0
    
    public init(_ seconds:Double) {
        self.seconds = seconds
        super.init("pause")
    }
}

public class PutMessage : Message {
    var message:String
    
    public override init(_ message:String) {
        self.message = message
        super.init("put")
    }
    
    public override var description : String {
        return "\(self.name) - \(self.message)";
    }
}

public class EchoMessage : Message {
    var message:String
    
    public override init(_ message:String) {
        self.message = message
        super.init("echo")
    }
    
    public override var description : String {
        return "\(self.name) - \(self.message)";
    }
}

public class LabelMessage : Message {
    var label:String
    
    public override init(_ label:String) {
        self.label = label
        super.init("label")
    }
    
    public override var description : String {
        return "\(self.name) - \(self.label)";
    }
}

public class GotoMessage : Message {
    var label:String
    
    public override init(_ label:String) {
        self.label = label
        super.init("goto")
    }
    
    public override var description : String {
        return "\(self.name) - \(self.label)";
    }
}

public class VarMessage : Message {
    var identifier:String
    var value:String
    
    public init(_ identifier:String, _ value:String) {
        self.identifier = identifier
        self.value = value
        super.init("var")
    }
    
    public override var description : String {
        return "\(self.name) - \(self.identifier):\(self.value)";
    }
}

@objc
public protocol INotifyMessage {
    func notify(message:TextTag)
    func sendCommand(command:CommandContext)
    func sendEcho(echo:String)
}

@objc
public class NotifyMessage : INotifyMessage {
    
    class func newInstance() -> NotifyMessage {
        return NotifyMessage()
    }
    
    var messageBlock: ((message:TextTag) -> Void)?
    var commandBlock: ((command:CommandContext) -> Void)?
    var echoBlock: ((echo:String) -> Void)?
    
    public init() {
    }

    public func notify(message:TextTag) {
        self.messageBlock?(message: message)
    }
    
    public func sendCommand(command:CommandContext) {
        self.commandBlock?(command: command)
    }
    
    public func sendEcho(echo:String) {
        self.echoBlock?(echo: echo)
    }
}

public protocol IAcceptMessage {
    func sendMessage(msg:Message);
}

public protocol IScript : IAcceptMessage {
    var scriptName:String { get }
   
    func cancel()
    func pause()
    func resume()
    func vars()
    func notify(message: TextTag)
    func stream(text:String, nodes:[Node])
}

public protocol Actor {
    func addOperation(op:NSOperation);
}

public class Thread : Actor {
    lazy var queue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Script queue"
//        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    var notifier:INotifyMessage?
    
    public init(_ notifier:INotifyMessage) {
        self.notifier = notifier
    }
    
    public func addOperation(op:NSOperation) {
        queue.addOperation(op);
    }
}

public class BaseOp : NSOperation {
    
    var _paused = false
    
    public var uuid = NSUUID()
    
    public func pause() {
        self._paused = true
    }
    
    public func resume() {
        self._paused = false
    }
}

public enum ScriptLogLevel : Int {
    case None = 0
    case Method = 5
}

public class Script : BaseOp, IScript {
  
    public var scriptName:String
    var notifier:INotifyMessage
    var actor:Actor
    var context:ScriptContext?
    var started:NSDate?
    var logLevel = ScriptLogLevel.None
    
    private var nextAfterUnpause = false
    private var nextAfterRoundtime = false
    
    let tokenToMessage = TokenToMessage()
    var currentLine:Int?
    var currentColumn:Int?
    
    public init(_ scriptName:String, _ notifier:INotifyMessage, _ actor:Actor) {
        self.scriptName = scriptName
        self.notifier = notifier
        self.actor = actor
    }
    
    public override func main () {
        autoreleasepool {
            
            self.started = NSDate()
            
            self.sendMessage(ScriptInfoMessage("Starting \(self.scriptName)\n"))
            
            while !self.cancelled {
            }
            
            self.currentLine = nil
            self.currentColumn = nil
            
            let diff = NSDate().timeIntervalSinceDate(self.started!)
            
            self.sendMessage(ScriptInfoMessage(String(format: "Script \(self.scriptName) completed - %.02f seconds total run time\n", diff)))
        }
    }
    
    override public func resume() {
        super.resume()
        
        if nextAfterUnpause {
            nextAfterUnpause = false
            self.moveNext()
        }
    }
    
    public func vars() {
    }
    
    public func stream(text:String, nodes:[Node]) {
        
        if self.nextAfterRoundtime {
            self.doNextAfterRoundtime(nodes)
        }
    }
    
    private func doNextAfterRoundtime(nodes:[Node]) {
        for node in nodes {
            if node.name == "prompt" {
                self.nextAfterRoundtime = false
                if let roundtime = self.context!.roundtime() {
                    if roundtime > 0 {
                        after(roundtime) {
                            self.moveNext()
                        }
                        return
                    }
                }
                
                self.moveNext()
            }
        }
    }
    
    public func run(script:String, globalVars:(()->[String:String])?, params:[String]) {
        let parser = OutlanderScriptParser()
        let tokens = parser.parseString(script)
        
        self.context = ScriptContext(tokens, globalVars: globalVars, params: params)
        self.moveNext()
    }
    
    public func moveNextAfterRoundtime() {
        
        if let roundtime = self.context!.roundtime() {
            if roundtime > 0 {
                after(roundtime) {
                    self.moveNext()
                }
                return
            }
        }
        
        self.nextAfterRoundtime = true
    }
    
    public func moveNext() {
        
        if self.cancelled {
            return
        }
        
        if self._paused {
            self.nextAfterUnpause = true
            return
        }
        
        var result = self.context!.next()
        if let nextToken = result {
            
            self.currentLine = nextToken.originalStringLine
            
            println("next - \(nextToken.description)")
            
            if let msg = tokenToMessage.toMessage(self.context!, token: nextToken) {
                self.sendMessage(msg)
            } else {
                println("canceling with no message")
                // end of script
                self.cancel()
            }
        } else {
            println("canceling from iteration")
            // end of script
            self.cancel()
        }
    }
    
    public func sendMessage(msg:Message) {
        
        if self.cancelled && !(msg is ScriptInfoMessage) {
            return
        }
        
        if let opComplete = msg as? OperationComplete {
            self.notify(TextTag(with: "\(opComplete.description) - \(opComplete.msg)\n", mono: true))
            if opComplete.operation == "pause" {
                self.moveNextAfterRoundtime()
            }
            else {
                self.moveNext()
            }
        }
        else if let pauseMsg = msg as? PauseMessage {
            self.actor.addOperation(PauseOp(self, seconds: pauseMsg.seconds))
        }
        else if let debugMsg = msg as? DebugLevelMessage {
            self.logLevel = debugMsg.level
            self.notify(TextTag(with: "debuglevel \(debugMsg.level)\n", mono: true))
            self.moveNext()
        }
        else if let putMsg = msg as? PutMessage {
            
            self.notify(TextTag(with: "put: \(putMsg.message)\n", mono: true))
            self.sendCommand(putMsg.message)
            self.moveNext()
        }
        else if let echoMsg = msg as? EchoMessage {
            
            self.notify(TextTag(with: "echo: \(echoMsg.message)\n", mono: true))
            self.sendEcho(echoMsg.message)
            
            self.moveNext()
        }
        else if let labelMsg = msg as? LabelMessage {
            self.notify(TextTag(with: "passing label: \(labelMsg.label)\n", mono: true))
            self.moveNext()
        }
        else if let gotoMsg = msg as? GotoMessage {
            self.notify(TextTag(with: "goto label: \(gotoMsg.label)\n", mono: true))
            self.context?.gotoLabel(gotoMsg.label)
            self.moveNext()
        }
        else if let varMsg = msg as? VarMessage {
            self.context?.setVariable(varMsg.identifier, value: varMsg.value)
            self.notify(TextTag(with: "setvariable \(varMsg.identifier) \(varMsg.value)\n", mono: true))
            self.moveNext()
        }
        else if let unkownMsg = msg as? UnknownMessage {
            let txtMsg = TextTag(with: "unkown command: \(unkownMsg.description)\n", mono: true)
            txtMsg.color = "#efefef"
            txtMsg.backgroundColor = "#ff3300"
            self.notify(txtMsg)
            self.moveNext()
        }
        else if let scriptInfo = msg as? ScriptInfoMessage {
            let txtMsg = TextTag(with: scriptInfo.description, mono: true)
            txtMsg.color = "#acff2f"
            self.notify(txtMsg)
        }
        else {
            self.notify(TextTag(with: "\(msg.description)\n", mono: true))
            self.moveNext()
        }
    }
    
    public func notify(message: TextTag) {
        
        message.scriptName = self.scriptName
        
        var line = self.currentLine != nil ? Int32(self.currentLine!) : -1
        message.scriptLine = line
        
        if message.color == nil {
            message.color = "#0066cc"
        }
        
        self.notifier.notify(message)
    }
    
    public func sendEcho(echo:String) {
        self.notifier.sendEcho("\(echo)\n")
    }
    
    public func sendCommand(command: String) {
        
        var ctx = CommandContext()
        ctx.command = command
        
        var line = self.currentLine != nil ? Int32(self.currentLine!) : -1
        ctx.scriptName = self.scriptName
        ctx.scriptLine = line
        
        self.notifier.sendCommand(ctx)
    }
}

public class TokenToMessage {
    
    public func toMessage(context:ScriptContext, token:Token) -> Message? {
        
        var msg:Message? = UnknownMessage(token.description)
        
        if let branch = token as? BranchToken {
            
            msg = OperationComplete("branch", msg: branch.lastResult ?? "")
            
        }
        else if let label = token as? LabelToken {
            
            msg = LabelMessage(label.characters)
            
        }
        else if let cmd = token as? CommandToken {
            switch cmd.name {
                
            case "echo":
                msg = EchoMessage(cmd.bodyText())
                
            case "goto":
                msg = GotoMessage(context.simplifyEach(cmd.body))
                
            case "put":
                msg = PutMessage(context.simplifyEach(cmd.body))
                
            case "pause":
                var lengthStr = cmd.bodyText().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                msg = PauseMessage(lengthStr.toDouble()!)
                
            case "debuglevel":
                var levelStr = cmd.bodyText().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                msg = DebugLevelMessage(levelStr.toInt()!)
                
            case "var", "setvariable":
                
                var txt = cmd.bodyText().componentsSeparatedByString(" ")
                
                var identifier = txt.removeAtIndex(0)
                var value = " ".join(txt)
                
                msg = VarMessage(identifier, value)
                
            default:
                msg = UnknownMessage(token.description)
            }
        }
        
        return msg
    }
}

public class PauseOp : BaseOp {
    
    var actor:IScript
    var seconds:Double
    
    init(_ actor:IScript, seconds:Double) {
        self.actor = actor
        self.seconds = seconds
    }
    
    public override func main () {
        autoreleasepool() {
            var text = String(format: "pausing for %.02f seconds\n", self.seconds)
            var txtMsg = TextTag(with: text, mono: true)
            txtMsg.color = "#efefef"
            txtMsg.backgroundColor = "#ff3300"
            self.actor.notify(txtMsg)
            
            after(self.seconds) {
                self.actor.sendMessage(OperationComplete("pause", msg: ""))
            }
        }
    }
}

private func after(seconds:Double, complete:()->Void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC))),
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            
        complete()
    }
}

extension String {
    
    func toDouble() -> Double? {
        enum F {
            static let formatter = NSNumberFormatter()
        }
        if let number = F.formatter.numberFromString(self) {
            return number.doubleValue
        }
        return nil
    }
    
    func substringFromIndex(index:Int) -> String {
        return self.substringFromIndex(advance(self.startIndex, index))
    }
    
    func indexOfCharacter(char: Character) -> Int? {
        if let idx = find(self, char) {
            return distance(self.startIndex, idx)
        }
        return nil
    }
}