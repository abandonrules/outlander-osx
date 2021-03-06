//
//  MMScrollView.m
//  MiniMail
//
//  Created by DINH Viêt Hoà on 24/08/10.
//  Copyright 2011 Sparrow SAS. All rights reserved.
//

#import "MMScrollView.h"

@implementation MMScrollView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setWantsLayer:YES];
    }
    return self;
}

- (void) tile
{
	NSRect frame;
	CGFloat height;
    
	[[self contentView] setFrame:[self bounds]];
    height = [self bounds].size.height;
	frame = NSMakeRect([self bounds].size.width - 15, 0, 15, height);
	[[self verticalScroller] setFrame:frame];
	
	[[self verticalScroller] removeFromSuperview];
	[self addSubview:[self verticalScroller]];
}

@end
