//
//  ShadowView.m
//  MobilePitch
//
//  Created by Nathan Wallace on 11/4/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "ShadowView.h"

@interface ShadowView ()

@property (strong, nonatomic) CALayer *shadowLayer;

@end

@implementation ShadowView

- (void)layoutSubviews {
    if (!_shadowLayer) {
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor clearColor] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1] CGColor], nil];
        self.shadowLayer = gradient;
        [self.layer insertSublayer:gradient atIndex:0];
    }
    self.shadowLayer.frame = self.bounds;
}

@end
