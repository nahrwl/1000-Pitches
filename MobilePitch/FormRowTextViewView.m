//
//  FromRowTextViewView.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/27/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "FormRowTextViewView.h"

@implementation FormRowTextViewView

- (id)initWithFrame:(CGRect)frame {
    if (self=[super initWithFrame:frame]) {
        // Text field
        UITextView *textView = [[UITextView alloc] init];
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:textView];
        self.textView = textView;
        [self.inputView addSubview:textView];
        // Appearance
        textView.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        textView.textColor = [UIColor blackColor];
        textView.backgroundColor = [UIColor colorWithRed:0.988 green:0.988 blue:0.988 alpha:1];
        textView.layer.borderColor = [[UIColor colorWithRed:0.886 green:0.886 blue:0.886 alpha:1] CGColor];
        textView.layer.borderWidth = 1.0f;
        textView.layer.cornerRadius = 8.0f;
        textView.textContainerInset = UIEdgeInsetsMake(14, 8, 14, 8);
    }
    return self;
}

- (void)updateConstraints {
    [self.inputView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textView(128)]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"textView":self.textView}]];
    [self.inputView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textView]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"textView" : self.textView}]];
    
    [super updateConstraints];
}

#pragma mark First Responder Status

- (BOOL)becomeFirstResponder {
    return [self.textView becomeFirstResponder];
}

@end
