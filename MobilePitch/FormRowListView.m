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
#import "FormRowListViewCell.h"

#define kBorderColor [UIColor colorWithRed:0.886 green:0.886 blue:0.886 alpha:1]
#define kBackgroundColor [UIColor colorWithRed:0.988 green:0.988 blue:0.988 alpha:1]

@interface FormRowListView ()

@property (strong, nonatomic, readwrite) NSArray<SmarterTextField *> *textFields;
@property (nonatomic) NSInteger selectedRowIndex;
@property (weak, nonatomic) FormRowListViewCell *selectedRow;

@property (weak, nonatomic) UIStackView *stackView;

- (void)rowButtonTapped:(UIButton *)sender;

@end

@implementation FormRowListView

- (instancetype)initWithRows:(NSUInteger)rows
{
    if (self = [super initWithFrame:CGRectZero])
    {
        _selectedRowIndex = -1;
        
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
            SmarterTextField *newField = [self createRowAtIndex:i];
            [tempTextFieldsArray addObject:newField];
        }
        
        _textFields = [tempTextFieldsArray copy];
    }
    return self;
}

// A UIButton is the superview of the text field and the checkmark image view
// This method returns the text field for the purposes of adding it to
// the text field array
- (SmarterTextField *)createRowAtIndex:(int)index
{
    // Create the row
    FormRowListViewCell *cell = [[FormRowListViewCell alloc] init];
    cell.translatesAutoresizingMaskIntoConstraints = NO;
    [self.stackView addArrangedSubview:cell];
    cell.button.tag = index + 2000;
    [cell.button addTarget:self action:@selector(rowButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.stackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[cell(46)]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"cell":cell}]];
    [self.stackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cell]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"cell" : cell}]];
    
    // Create the row separator
    UIView *rowSeparator = [[UIView alloc] init];
    rowSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.stackView addArrangedSubview:rowSeparator];
    
    rowSeparator.backgroundColor = kBorderColor;
    [self.stackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[rowSeparator(1)]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"rowSeparator":rowSeparator}]];
    [self.stackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[rowSeparator]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"rowSeparator" : rowSeparator}]];
    
    return cell.textField;
}

- (void)rowButtonTapped:(UIButton *)sender
{
    NSInteger index = sender.tag - 2000;
    [self.delegate rowSelected:index forView:self];
    
    // Update the view
    FormRowListViewCell *cell = (FormRowListViewCell *)sender.superview;
    
    // Deselect the old view
    if (self.selectedRow)
    {
        [self.selectedRow setSelected:NO];
    }
    
    // Select the new view
    [cell setSelected:YES];
    
    // Update the selected row property
    self.selectedRowIndex = index;
    self.selectedRow = cell;
}

- (NSString *)value
{
    return self.selectedRow.textField.text;
}

@end
