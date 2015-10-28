//
//  NicerLookingPickerView.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/27/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//
//  This subclass is a real doozy
//  Trust me.

#import "NicerLookingPickerView.h"

@implementation NicerLookingPickerView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Give the picker view a light background color
    self.backgroundColor = [UIColor whiteColor];
    
    // Add the top border that really puts this Picker View subclass in the "nicer looking" category
    
    // Create the border layer
    CALayer *topBorder = [[CALayer alloc] init];
    
    // Give the border full width and 0.5f thickness
    topBorder.frame = CGRectMake(0, 0, self.frame.size.width, 0.5f);
    
    // Set the background color to be a tasteful light grey
    topBorder.backgroundColor = [[UIColor colorWithRed:0.804 green:0.804 blue:0.804 alpha:1] CGColor];
    
    // Add the top border layer to the Nicer Looking Picker View
    [self.layer addSublayer:topBorder];
    
}

@end
