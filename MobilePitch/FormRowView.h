//
//  FormRowView.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/25/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FormRowView : UIView

@property (weak, nonatomic) UITextField *textField;

- (NSString *)title;
- (void)setTitle:(NSString *)title required:(BOOL)required;

@end
