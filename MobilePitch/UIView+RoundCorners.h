//
//  UIView+RoundCorners.h
//  MobilePitch
//
//  http://stackoverflow.com/a/37577501
//

#import <UIKit/UIKit.h>

@interface UIView (RoundCorners)

/**
 Rounds the given set of corners to the specified radius
 
 - parameter corners: Corners to round
 - parameter radius:  Radius to round to
 */
- (void)roundCorners:(UIRectCorner)corners radius:(CGFloat)radius;

/**
 Rounds the given set of corners to the specified radius with a border
 
 - parameter corners:     Corners to round
 - parameter radius:      Radius to round to
 - parameter borderColor: The border color
 - parameter borderWidth: The border width
 */
- (void)roundCorners:(UIRectCorner)corners radius:(CGFloat)radius borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth;

/**
 Fully rounds an autolayout view (e.g. one with no known frame) with the given diameter and border
 
 - parameter diameter:    The view's diameter
 - parameter borderColor: The border color
 - parameter borderWidth: The border width
 */
- (void)fullyRoundWithDiameter:(CGFloat)diameter borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth;

@end
