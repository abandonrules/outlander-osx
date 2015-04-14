//
//  RoomChangeHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 4/5/15.
//  Copyright (c) 2015 Joe McBride. All rights reserved.
//

import Foundation

@objc
public protocol NodeHandler {
    func handle(nodes:[Node], text:String, context:GameContext)
}

@objc
class RoomChangeHandler : NodeHandler {
    
    var commandRelay = GameCommandRelay()
    
    private var showAfterPrompt = false
    
    class func newInstance() -> RoomChangeHandler {
        return RoomChangeHandler()
    }
    
    func handle(nodes:[Node], text:String, context:GameContext) {
        
        if let zone = context.mapZone {
            
            for node in nodes {
                
                if node.name == "compass" {
                    
                    self.showAfterPrompt = true
                }
                
                if node.name == "prompt" && self.showAfterPrompt {
                    
                    self.showAfterPrompt = false
                    
                    var title = context.globalVars.cacheObjectForKey("roomtitle") as? String ?? ""
                    var desc = context.globalVars.cacheObjectForKey("roomdesc") as? String ?? ""
                    
                    title = title.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "[]"))
                    
                    var roomId = context.globalVars.cacheObjectForKey("roomid") as? String
                    
                    self.findRoom(context, zone: zone, previousRoomId: roomId, name: title, description: desc)
                    
                }
            }
        }
    }
    
    func findRoom(context:GameContext, zone:MapZone, previousRoomId:String?, name:String, description:String) {
        
        { () -> Void in
            let start = NSDate()
        
            if let room = zone.findRoomFuzyFrom(previousRoomId, name: name, description: description) {
                let diff = NSDate().timeIntervalSinceDate(start)
                
                self.send(context, room: room, diff: diff)
            }
            
        } ~> { () -> Void in
        }
    }
    
    func send(context:GameContext, room:MapNode, diff:Double) {
        
        context.globalVars.setCacheObject(room.id, forKey: "roomid")
        
        var tag = TextTag()
        
        if context.globalVars.cacheObjectForKey("debugautomapper") as? String == "1" {
        
            tag.text = "[AutoMapper] Debug: Found room #\(room.id) in \(diff) seconds\n"
            tag.color = "#00ffff"
            self.commandRelay.sendEcho(tag)
        }
        
        var exits = ", ".join(room.nonCardinalExists().map { $0.move })
        
        if count(exits) > 0 {
        
            tag = TextTag()
            tag.text = "Mapped exits: \(exits)\n"
            tag.color = "#00ffff"
            self.commandRelay.sendEcho(tag)
            
        }
    }
}