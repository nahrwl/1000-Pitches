//
//  SplashView.m
//  MobilePitch
//
//  Created by Nathan Wallace on 11/6/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "SplashView.h"

@interface SplashView ()

@property (strong, nonatomic) UIView *gridView;
@property (strong, nonatomic) UIImageView *gradientBackground;

@end

@implementation SplashView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)init {
    if (self = [super init]) {
        _gradientBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient-background"]];
        [self addSubview:_gradientBackground];
        
        _gridView = [[UIView alloc] init];
        //_gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"grid-unit"]];
        [self addSubview:_gridView];
    }
    return self;
}

- (void)layoutSubviews {
    self.gradientBackground.frame = self.bounds;
    self.gridView.frame = self.bounds;
}

@end
