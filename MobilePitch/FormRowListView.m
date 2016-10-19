//
//  FormRowListView.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/17/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import "FormRowListView.h"
#import "SmarterTextField.h"
#import "UIView+RoundCorners.h"

#define kBorderColor [UIColor colorWithRed:0.886 green:0.886 blue:0.886 alpha:1]

@interface FormRowListView ()

@property (strong, nonatomic, readwrite) NSArray<SmarterTextField *> *textFields;

@property (weak, nonatomic) UIStackView *stackView;

@end

@implementation FormRowListView

- (instancetype)initWithRows:(NSUInteger)rows
{
    if (self = [super initWithFrame:CGRectZero])
    {
        // Create a temporary mutable array
        NSMutableArray *tempTextFieldsArray = [[NSMutableArray alloc] initWithCapacity:rows];
        
        // Give the input view some formatting
        [self.inputView fullyRoundWithDiameter:16.0 borderColor:kBorderColor borderWidth:1.0f];
        
        // Create the stack view to hold the rows
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.distribution = UIStackViewDistributionFill;
        [self.inputView addSubview:stackView];
        self.stackView = stackView;
        
        // Stack view
        [self.inputView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[stackView]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"stackView":self.stackView}]];
        [self.inputView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[stackView]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"stackView" : self.stackView}]];
        
        for (int i = 0; i < rows; i++)
        {
            SmarterTextField *newField = [self createRow];
            [tempTextFieldsArray addObject:newField];
        }
        
        _textFields = [tempTextFieldsArray copy];
    }
    return self;
}

// A UIButton is the superview of the text field and the checkmark image view
// This method returns the text field for the purposes of adding it to
// the text field array
- (SmarterTextField *)createRow
{
    // Create the button, which is the text field superview
    UIButton *superButton = [[UIButton alloc] init];
    superButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.stackView addArrangedSubview:superButton];
    
    // Format the button view
    superButton.backgroundColor = [UIColor colorWithRed:0.988 green:0.988 blue:0.988 alpha:1];
    
    // Button superview
    [self.stackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button(46)]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"button":superButton}]];
    [self.stackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"button" : superButton}]];
    
    // Create the row separator
    UIView *rowSeparator = [[UIView alloc] init];
    rowSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.stackView addArrangedSubview:rowSeparator];
    
    rowSeparator.backgroundColor = kBorderColor;
    [self.stackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[rowSeparator(1)]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"rowSeparator":rowSeparator}]];
    [self.stackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[rowSeparator]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"rowSeparator" : rowSeparator}]];
    
    
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
    
    // Button subviews autolayout
    [superButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textField]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"textField" : textField}]];
    [superButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textField]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"textField" : textField}]];
    
    return textField;
}

@end
