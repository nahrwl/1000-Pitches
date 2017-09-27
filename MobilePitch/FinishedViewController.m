//
//  FinishedViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/4/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import "FinishedViewController.h"
#import "SplashView.h"

#define kViewAnimationDuration 2.0f
#define kViewAnimationDelayDuration 1.0f
#define kViewAnimationShortDuration 1.0f

@interface FinishedViewController ()

@property (weak, nonatomic) UILabel *titleLabel;
@property (weak, nonatomic) UIImageView *logo;
@property (weak, nonatomic) UIButton *button;
@property (weak, nonatomic) UIImageView *sponsor1;
@property (weak, nonatomic) UIImageView *sponsor2;
@property (weak, nonatomic) UIImageView *sponsor3;

@property (weak, nonatomic) NSLayoutConstraint *logoVPosition;

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
    
    self.sponsor1.alpha = 0.0f;
    self.sponsor1.opaque = NO;
    self.sponsor2.alpha = 0.0f;
    self.sponsor2.opaque = NO;
    self.sponsor3.alpha = 0.0f;
    self.sponsor3.opaque = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:kViewAnimationShortDuration
                          delay:kViewAnimationShortDuration
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
    {
        self.titleLabel.alpha = 1.0f;
    }
                     completion:^(BOOL finished)
    {
        self.titleLabel.opaque = YES;
    }];
    
    [UIView animateWithDuration:kViewAnimationShortDuration
                          delay:kViewAnimationShortDuration * 3
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
     {
         self.sponsor1.alpha = 1.0f;
     }
                     completion:^(BOOL finished)
     {
         self.sponsor1.opaque = YES;
     }];
    
    [UIView animateWithDuration:kViewAnimationShortDuration
                          delay:kViewAnimationShortDuration * 4
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
     {
         self.sponsor2.alpha = 1.0f;
     }
                     completion:^(BOOL finished)
     {
         self.sponsor2.opaque = YES;
     }];
    
    [UIView animateWithDuration:kViewAnimationShortDuration
                          delay:kViewAnimationShortDuration * 5
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
     {
         self.sponsor3.alpha = 1.0f;
     }
                     completion:^(BOOL finished)
     {
         self.sponsor3.opaque = YES;
     }];
    
    
    [UIView animateWithDuration:kViewAnimationDuration
                          delay:kViewAnimationDelayDuration * 6
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
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: @"Pitch Again"];
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
    
    // Sponsors
    UIImageView *s1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"greif-sponsor"]];
    s1.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:s1];
    self.sponsor1 = s1;
    
    UIImageView *s2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"marshall-sponsor"]];
    s2.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:s2];
    self.sponsor2 = s2;
    
    UIImageView *s3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"spark-sponsor"]];
    s3.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:s3];
    self.sponsor3 = s3;
    
    // AUTOLAYOUT
    NSDictionary *views = NSDictionaryOfVariableBindings(titleLabel, button, logo, s1, s2, s3);
    
    // Sponsors
    [s1.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
    [s2.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
    [s3.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
    [s1.bottomAnchor constraintEqualToAnchor:s2.topAnchor constant:0].active = YES;
    [s2.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
    [s3.topAnchor constraintEqualToAnchor:s2.bottomAnchor constant:0].active = YES;
    
    
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
    UILayoutGuide *titleLayoutGuide = [[UILayoutGuide alloc] init];
    [view addLayoutGuide:titleLayoutGuide];
    
    [titleLayoutGuide.topAnchor constraintEqualToAnchor:view.layoutMarginsGuide.topAnchor].active = YES;
    [titleLayoutGuide.bottomAnchor constraintEqualToAnchor:s1.topAnchor].active = YES;
    
    [titleLabel.centerYAnchor constraintEqualToAnchor:titleLayoutGuide.centerYAnchor].active = YES;
    
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
                                  constant:0];
    [view addConstraint:logoCenterYConstraint];
    self.logoVPosition = logoCenterYConstraint;
    
    
    // Button detail
    NSArray *arrowHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[arrow]-13-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"arrow":arrow}];
    NSArray *arrowVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[arrow]-15-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"arrow":arrow}];
    [button addConstraints:arrowHConstraints];
    [button addConstraints:arrowVConstraints];
}

@end
