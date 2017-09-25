//
//  FinishedViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/4/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import "FinishedViewController.h"
#import "SplashView.h"

#define kViewAnimationDuration 4.0f
#define kViewAnimationDelayDuration 1.0f
#define kViewAnimationShortDuration 1.0f

@interface FinishedViewController ()

@property (weak, nonatomic) UILabel *titleLabel;
@property (weak, nonatomic) UIImageView *logo;
@property (weak, nonatomic) UIButton *button;

@end

@implementation FinishedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Hide the navigation bar
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    // Prepare the subviews for animation
    self.titleLabel.alpha = 0.0f;
    self.titleLabel.opaque = NO;
    self.logo.alpha = 0.0f;
    self.logo.opaque = NO;
    self.button.alpha = 0.0f;
    self.button.opaque = NO;
    self.button.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:kViewAnimationShortDuration
                          delay:kViewAnimationDelayDuration * 3
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
    {
        self.titleLabel.alpha = 1.0f;
    }
                     completion:^(BOOL finished)
    {
        self.titleLabel.opaque = YES;
    }];
    
    [UIView animateWithDuration:kViewAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
    {
        self.logo.alpha = 1.0f;
    }
                     completion:^(BOOL finished)
    {
        self.logo.opaque = YES;
    }];
    
    [UIView animateWithDuration:kViewAnimationShortDuration
                          delay:(kViewAnimationDelayDuration * 3)
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
     {
         self.button.alpha = 1.0f;
     }
                     completion:^(BOOL finished)
     {
         self.button.opaque = YES;
         self.button.enabled = YES;
     }];
    
    // Sets timer to reset app automagically
    [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(homeButtonTapped:) userInfo:nil repeats:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)homeButtonTapped:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)loadView
{
    SplashView *view = [[SplashView alloc] init];
    self.view = view;
    
    // Title text
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:titleLabel];
    self.titleLabel = titleLabel;
    // Title text formatting
    titleLabel.text = @"Submission complete!";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor whiteColor];
    
    
    
    // Continue Button
    UIButton *button = [[UIButton alloc] init];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:button];
    self.button = button;
    // Button formatting
    button.backgroundColor = [UIColor colorWithRed:0.741 green:0.0627 blue:0.878 alpha:1];
    button.layer.cornerRadius = 8;
    // Button titleLabel formatting
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: @"Home"];
    [attributedString addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:21 weight:UIFontWeightBold]
                             range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:[UIColor whiteColor]
                             range:NSMakeRange(0, attributedString.length)];
    [button setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    // Button detail arrow
    UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"right arrow"]];
    arrow.translatesAutoresizingMaskIntoConstraints = NO;
    [button addSubview:arrow];
    
    // Button Action
    [button addTarget:self action:@selector(homeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // 1000 pitches logo
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_group"]];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:logo];
    self.logo = logo;
    
    
    // AUTOLAYOUT
    NSDictionary *views = NSDictionaryOfVariableBindings(titleLabel, button, logo);
    
    // Horizontal
    NSArray *horizontalButtonLayoutConstraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-32-[button]-32-|"
                                            options:NSLayoutFormatAlignAllCenterY
                                            metrics:nil
                                              views:views];
    [view addConstraints:horizontalButtonLayoutConstraints];
    
    NSLayoutConstraint *titleCenterXConstraint =
    [NSLayoutConstraint constraintWithItem:titleLabel
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1.0
                                  constant:0.0];
    [view addConstraint:titleCenterXConstraint];
    
    NSLayoutConstraint *logoCenterXConstraint =
    [NSLayoutConstraint constraintWithItem:logo
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1.0
                                  constant:0.0];
    [view addConstraint:logoCenterXConstraint];
    
    // Vertical
    NSArray *verticalLayoutConstraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-95-[titleLabel]"
                                            options:NSLayoutFormatAlignAllCenterX
                                            metrics:nil
                                              views:views];
    [view addConstraints:verticalLayoutConstraints];
    
    NSArray *verticalLayoutConstraints2 =
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:[button(48)]-32-|"
                                            options:NSLayoutFormatAlignAllCenterX
                                            metrics:nil
                                              views:views];
    [view addConstraints:verticalLayoutConstraints2];
    
    NSLayoutConstraint *logoCenterYConstraint =
    [NSLayoutConstraint constraintWithItem:logo
                                 attribute:NSLayoutAttributeCenterY
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view
                                 attribute:NSLayoutAttributeCenterY
                                multiplier:1.0
                                  constant:0.0];
    [view addConstraint:logoCenterYConstraint];
    
    
    // Button detail
    NSArray *arrowHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[arrow]-13-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"arrow":arrow}];
    NSArray *arrowVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[arrow]-15-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"arrow":arrow}];
    [button addConstraints:arrowHConstraints];
    [button addConstraints:arrowVConstraints];
}

@end
