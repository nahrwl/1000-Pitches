//
//  FormTableViewCell.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/25/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "FormTableViewCell.h"

@interface FormTableViewCell ()

@property (weak, nonatomic) UILabel *titleLabel;

@end

@implementation FormTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // Configure the cell
        UIView *contentView = self.contentView;
        contentView.clipsToBounds = YES;
        contentView.backgroundColor = [UIColor colorWithRed:0.953 green:0.953 blue:0.953 alpha:1];
        
        // Field title
        UILabel *title = [[UILabel alloc] init];
        title.translatesAutoresizingMaskIntoConstraints = NO;
        [contentView addSubview:title];
        self.titleLabel = title;
        // Appearance is set in the designated setter
        [self setTitle:@"Test Title" required:YES];
        
        // Text field
        UITextField *textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [contentView addSubview:textField];
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
        
        
        // Autolayout
        NSDictionary *views = NSDictionaryOfVariableBindings(title, textField);
        
        NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[title]-4-[textField(46)]->=8-|" options:NSLayoutFormatAlignAllLeft metrics:nil views:views];
        [contentView addConstraints:vConstraints];
        
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:33]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:textField attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-33]];
        
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark Getters and Setters

- (void)setTitle:(NSString *)title required:(BOOL)required {
    NSString *titleText;
    if (required) {
        titleText = [title stringByAppendingString:@" *"];
    } else {
        titleText = title;
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:titleText];
    
    if (required) {
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:[UIColor colorWithRed:0.796 green:0 blue:0 alpha:1]
                                 range:NSMakeRange(0, attributedString.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:[UIColor colorWithRed:0.396 green:0.396 blue:0.396 alpha:1]
                                 range:NSMakeRange(0, attributedString.length - 1)];
        
    } else {
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:[UIColor colorWithRed:0.396 green:0.396 blue:0.396 alpha:1]
                                 range:NSMakeRange(0, attributedString.length)];
    }
    [attributedString addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]
                             range:NSMakeRange(0, attributedString.length)];
    [self.titleLabel setAttributedText:attributedString];
    
    NSLog(@"title label height: %f",self.titleLabel.frame.size.height);
}

- (NSString *)title {
    return self.titleLabel.text;
}

@end
