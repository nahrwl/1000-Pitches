//
//  FormRowView.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/25/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "FormRowView.h"
#import "SmarterTextField.h"

@interface FormRowView ()

@property (weak, nonatomic) UILabel *titleLabel;

@end

@implementation FormRowView

- (id)initWithFrame:(CGRect)frame {
    if (self=[super initWithFrame:frame]) {
        // Configure the cell
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor colorWithRed:0.953 green:0.953 blue:0.953 alpha:1];
        
        // Field title
        UILabel *title = [[UILabel alloc] init];
        title.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:title];
        self.titleLabel = title;
        // Appearance is set in the designated setter
        [self setTitle:@"Test Title" required:YES];
        
        // Text field
        SmarterTextField *textField = [[SmarterTextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:textField];
        self.textField = textField;
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
    // Autolayout
    NSDictionary *views = @{@"titleLabel":self.titleLabel,@"textField":self.textField};
    
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[titleLabel]-4-[textField(46)]->=8-|" options:NSLayoutFormatAlignAllLeft metrics:nil views:views];
    [self addConstraints:vConstraints];
    
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-33-[textField(>=50)]-33-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views];
    [self addConstraints:hConstraints];
    
    //[self addConstraint:[NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:33]];
    //[self addConstraint:[NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-33]];
    
    // Now call super. Important!
    [super updateConstraints];
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
}

- (NSString *)title {
    return self.titleLabel.text;
}

#pragma mark Class methods

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}


@end
