//
//  UIView+RoundCorners.m
//  MobilePitch
//
//  http://stackoverflow.com/a/37577501
//

#import "UIView+RoundCorners.h"

@implementation UIView (RoundCorners)

- (void)roundCorners:(UIRectCorner)corners radius:(CGFloat)radius {
    [self _roundCorners:corners radius:radius];
}

- (void)roundCorners:(UIRectCorner)corners radius:(CGFloat)radius borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth {
    CAShapeLayer *mask = [self _roundCorners:corners radius:radius];
    [self addBorderWithMask:mask borderColor:borderColor borderWidth:borderWidth];
}

- (void)fullyRoundWithDiameter:(CGFloat)diameter borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth {
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = diameter / 2;
    self.layer.borderWidth = borderWidth;
    self.layer.borderColor = borderColor.CGColor;
}

- (CAShapeLayer *)_roundCorners:(UIRectCorner)corners radius:(CGFloat)radius {
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = path.CGPath;
    self.layer.mask = mask;
    return mask;
}

- (void)addBorderWithMask:(CAShapeLayer *)mask borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth {
    CAShapeLayer *borderLayer = [CAShapeLayer layer];
    borderLayer.path = mask.path;
    borderLayer.fillColor = UIColor.clearColor.CGColor;
    borderLayer.strokeColor = borderColor.CGColor;
    borderLayer.lineWidth = borderWidth;
    borderLayer.frame = self.bounds;
    [self.layer addSublayer:borderLayer];
}

@end
