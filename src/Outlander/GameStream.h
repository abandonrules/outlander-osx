//
//  GameStream.h
//  Outlander
//
//  Created by Joseph McBride on 1/25/14.
//  Copyright (c) 2014 Joe McBride. All rights reserved.
//

#import "RACReplaySubject.h"
#import "GameServer.h"
#import "GameParser.h"
#import "GameConnection.h"
#import "TSMutableDictionary.h"

@interface GameStream : NSObject {
    GameServer *_gameServer;
    GameParser *_gameParser;
}
@property (atomic, strong) RACReplaySubject *subject;
@property (atomic, strong) TSMutableDictionary *globalVars;
@property (atomic, strong) RACSignal *connected;
@property (atomic, strong) RACSignal *vitals;
@property (atomic, strong) RACSignal *room;
@property (atomic, strong) RACSignal *exp;
@property (atomic, strong) RACSignal *thoughts;
@property (atomic, strong) RACSignal *arrivals;
@property (atomic, strong) RACSignal *deaths;
@property (atomic, strong) RACSignal *familiar;
@property (atomic, strong) RACSignal *log;
-(void) publish:(id)item;
-(void) complete;
-(void) error:(NSError *)error;
-(void) sendCommand:(NSString *)command;
-(RACSignal *) connect:(GameConnection *)connection;
@end
