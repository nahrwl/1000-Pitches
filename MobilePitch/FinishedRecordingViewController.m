//
//  FinishedRecordingViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/25/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "FinishedRecordingViewController.h"
#import "FormViewController.h"

@interface FinishedRecordingViewController ()

@property (weak, nonatomic) UILabel *timeLabel;

@end

@implementation FinishedRecordingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.timeLabel.text = self.finalTime;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Make nav bar hidden
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)submitButtonTapped {
    [self.delegate submitVideo];
}

- (void)cancelButtonTapped {
    [self.delegate tryAgain];
}

- (void)loadView {
    UIView *view = [[UIView alloc] init];
    self.view = view;
    /*
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        self.view.backgroundColor = [UIColor clearColor];
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.view.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.view addSubview:blurEffectView];
    }
    else {*/
        self.view.backgroundColor = [UIColor blackColor];
    //}
    
    // Cancel button
    UIButton *cancelButton = [[UIButton alloc] init];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:cancelButton];
    [cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    // Appearance
    [cancelButton setTitle:@"Try Again" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    [cancelButton setTitleColor:[UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1] forState:UIControlStateNormal];
    cancelButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    // Cancel button back arrow decal
    UIImageView *backArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tryagain-back"]];
    backArrow.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:backArrow];
    
    // Total time label
    UILabel *totalTimeLabel = [[UILabel alloc] init];
    totalTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:totalTimeLabel];
    // Appearance
    totalTimeLabel.text = @"Total Time:";
    totalTimeLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightLight];
    totalTimeLabel.textColor = [UIColor whiteColor];
    totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    
    // Time label
    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:timeLabel];
    self.timeLabel = timeLabel;
    // Appearance
    timeLabel.text = @"00:00";
    timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:72 weight:UIFontWeightSemibold];
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    
    // Continue Button
    UIButton *button = [[UIButton alloc] init];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:button];
    // Button formatting
    button.backgroundColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    button.layer.cornerRadius = 8;
    // Button titleLabel formatting
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: @"Continue"];
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
    [button addTarget:self action:@selector(submitButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    
    // AUTOLAYOUT
    NSDictionary *views = NSDictionaryOfVariableBindings(totalTimeLabel, timeLabel, button, cancelButton);
    
    // Button detail
    NSArray *arrowHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[arrow]-13-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"arrow":arrow}];
    NSArray *arrowVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[arrow]-15-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"arrow":arrow}];
    [button addConstraints:arrowHConstraints];
    [button addConstraints:arrowVConstraints];
    
    // Try again detail arrow
    [view addConstraint:[NSLayoutConstraint constraintWithItem:backArrow attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cancelButton attribute:NSLayoutAttributeLeft multiplier:1 constant:-10]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:backArrow attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cancelButton attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    // Horizontal
    NSArray *horizontalButtonLayoutConstraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-32-[button]-32-|"
                                            options:NSLayoutFormatAlignAllCenterY
                                            metrics:nil
                                              views:views];
    [view addConstraints:horizontalButtonLayoutConstraints];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:cancelButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:totalTimeLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    // Vertical
    
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-44-[cancelButton]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button]-32-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:timeLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:timeLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:totalTimeLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:timeLabel attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    
}

@end
