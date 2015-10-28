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

// Views
@property (weak, nonatomic) UILabel *titleLabel;
@property (weak, nonatomic, readwrite) UIView *inputView;

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
        
        UIView *inputView = [[UIView alloc] init];
        inputView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:inputView];
        self.inputView = inputView;
    }
    return self;
}

- (void)updateConstraints {
    // Autolayout
    NSDictionary *views = @{@"titleLabel":self.titleLabel,@"inputView":self.inputView};
    
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[titleLabel]-4-[inputView]->=8-|" options:NSLayoutFormatAlignAllLeft metrics:nil views:views];
    [self addConstraints:vConstraints];
    
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-33-[inputView]-33-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views];
    [self addConstraints:hConstraints];
    
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
