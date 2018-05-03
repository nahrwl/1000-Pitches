//
//  FormRowTextFieldView.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/27/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "FormRowTextFieldView.h"
#import "SmarterTextField.h"

@implementation FormRowTextFieldView

- (id)initWithFrame:(CGRect)frame {
    if (self=[super initWithFrame:frame]) {
        // Text field
        SmarterTextField *textField = [[SmarterTextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:textField];
        self.textField = textField;
        [self.inputView addSubview:textField];
        // Appearance
        textField.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        textField.textColor = [UIColor blackColor];
        textField.backgroundColor = [UIColor colorWithRed:0.988 green:0.988 blue:0.988 alpha:1];
        textField.layer.borderColor = [[UIColor colorWithRed:0.886 green:0.886 blue:0.886 alpha:1] CGColor];
        textField.layer.borderWidth = 1.0f;
        textField.layer.cornerRadius = 8.0f;
        UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 13, 16)];
        [textField setLeftViewMode:UITextFieldViewModeAlways];
        [textField setLeftView:spacerView];
    }
    return self;
}

- (void)updateConstraints {
    [self.inputView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textField(46)]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"textField":self.textField}]];
    [self.inputView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textField]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"textField" : self.textField}]];
    
    [super updateConstraints];
}

- (void)setError:(BOOL)error
{
    if (error) {
        self.textField.layer.borderColor = [UIColor colorWithRed:0.796 green:0 blue:0 alpha:1].CGColor;
    } else {
        self.textField.layer.borderColor = [UIColor colorWithRed:0.886 green:0.886 blue:0.886 alpha:1].CGColor;
    }
}

#pragma mark First Responder Status

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (BOOL)needsKeyboard
{
    return YES;
}

@end
