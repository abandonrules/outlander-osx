//
//  MyNSTextView.m
//  Outlander
//
//  Created by Joseph McBride on 5/20/14.
//  Copyright (c) 2014 Joe McBride. All rights reserved.
//

#import "MyNSTextView.h"

@implementation MyNSTextView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

- (void)keyUp:(NSEvent *)theEvent {
    char val = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    id<RACSubscriber> sub = (id<RACSubscriber>)self.keyupSignal;
    [sub sendNext:[NSString stringWithFormat:@"%c", val]];
}

@end
