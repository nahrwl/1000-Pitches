//
//  FormRowListViewCell.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/17/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import "FormRowListViewCell.h"
#import "SmarterTextField.h"

@interface FormRowListViewCell ()

@property (weak, nonatomic) UIImageView *checkmarkImageView;

@end

@implementation FormRowListViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        // Configure
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self configure];
        self.backgroundColor = [UIColor blueColor];
    }
    return self;
}

- (instancetype)init
{
    return self = [self initWithFrame:CGRectZero];
}

- (void)configure
{
    // Create the button, which is the text field superview
    UIButton *superButton = [[UIButton alloc] init];
    superButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:superButton];
    
    // Format the button view
    superButton.backgroundColor = [UIColor colorWithRed:0.988 green:0.988 blue:0.988 alpha:1];
    
    // Button superview
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button(46)]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"button":superButton}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"button" : superButton}]];
    
    // Create a row
    // Text field
    SmarterTextField *textField = [[SmarterTextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [superButton addSubview:textField];
    
    // Appearance
    textField.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    textField.textColor = [UIColor colorWithRed:0.231 green:0.231 blue:0.231 alpha:1];
    
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 13, 16)];
    [textField setLeftViewMode:UITextFieldViewModeAlways];
    [textField setLeftView:spacerView];
    
    textField.cursorEnabled = NO;
    textField.userInteractionEnabled = NO;
    
    // Create the image view
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark"]];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [superButton addSubview:imageView];
    imageView.hidden = YES;
    
    [imageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor];
    
    // Button subviews autolayout
    [superButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textField]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"textField" : textField}]];
    [superButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textField][imageView(13)]-13-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"textField" : textField, @"imageView" : imageView}]];
    
    _button = superButton;
    _textField = textField;
    _checkmarkImageView = imageView;
}

- (void)setChecked:(BOOL)checked
{
    // Display/hide the checkmark image
    self.checkmarkImageView.hidden = !checked;
    _checked = checked;
}

- (void)setSelected:(BOOL)selected
{
    if (selected) {
        self.textField.textColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
        self.checked = YES;
    } else {
        self.textField.textColor = [UIColor colorWithRed:0.231 green:0.231 blue:0.231 alpha:1];
        self.checked = NO;
    }
}


@end
