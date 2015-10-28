//
//  SmarterTextField.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/27/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//
//  I mean, Nicer Looking is never a bad thing,
//  but Smart is pretty hot too.

#import "SmarterTextField.h"

@implementation SmarterTextField

- (id)initWithFrame:(CGRect)frame {
    if (self=[super initWithFrame:frame]) {
        _cursorEnabled = YES;
    }
    return self;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
    if (!self.cursorEnabled) {
        return CGRectZero;
    }
    return [super caretRectForPosition:position];
}

@end
