//
//  WindowData.h
//  Outlander
//
//  Created by Joseph McBride on 5/1/14.
//  Copyright (c) 2014 Joe McBride. All rights reserved.
//

#import "Mantle.h"

@interface WindowData : MTLModel <MTLJSONSerializing>

+ (id)windowWithName:(NSString *)name atLoc:(NSRect)loc;
- (id)initWithName:(NSString *)name atLoc:(NSRect)loc;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) double x;
@property (nonatomic, assign) double y;
@property (nonatomic, assign) double height;
@property (nonatomic, assign) double width;

@end