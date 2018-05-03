//
//  FormRowListViewCell.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/17/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SmarterTextField;

@interface FormRowListViewCell : UIView

@property (weak, nonatomic) UIButton *button;
@property (weak, nonatomic) SmarterTextField *textField;
@property (nonatomic) BOOL checked;

- (void)setSelected:(BOOL)selected;

@end
