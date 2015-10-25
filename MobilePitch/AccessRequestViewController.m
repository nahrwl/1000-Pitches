//
//  AccessRequestViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/24/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

@import AVFoundation;

#import "AccessRequestViewController.h"

@interface AccessRequestViewController ()

@property (weak, nonatomic) UILabel *titleLabel;

// Actions
- (void)okButtonTapped;

@end

@implementation AccessRequestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"Width of titleLabel is: %f",self.titleLabel.frame.size.width);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)okButtonTapped {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)loadView {
    UIView *view = [[UIView alloc] init];
    self.view = view;
    
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        self.view.backgroundColor = [UIColor clearColor];
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.view.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.view addSubview:blurEffectView];
    }
    else {
        self.view.backgroundColor = [UIColor blackColor];
    }
    
    // Title text
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:titleLabel];
    [titleLabel sizeToFit];
    self.titleLabel = titleLabel;
    // Title text formatting
    titleLabel.text = @"Before We Begin";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor whiteColor];
    
    // Description text
    UILabel *descriptionLabel = [[UILabel alloc] init];
    descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:descriptionLabel];
    // Description text formatting
    descriptionLabel.text = @"First, we need access to your camera and microphone to\nrecord your pitch.";
    descriptionLabel.numberOfLines = 0; //undefined number of lines
    descriptionLabel.textAlignment = NSTextAlignmentNatural;
    descriptionLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightLight];
    descriptionLabel.textColor = [UIColor whiteColor];
    
    // OK Button
    UIButton *button = [[UIButton alloc] init];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:button];
    // Appearance
    [button setTitle:@"Grant Access" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:48 weight:UIFontWeightSemibold];
    [button setTitleColor:[UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(okButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    // Cancel Button
    UIButton *cancelButton = [[UIButton alloc] init];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:cancelButton];
    // Appearance
    [cancelButton setTitle:@"No Thanks" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    // AUTOLAYOUT
    NSDictionary *views = NSDictionaryOfVariableBindings(titleLabel, descriptionLabel, button, cancelButton);
    
    // Vertical
    NSArray *VLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-77-[titleLabel]-18-[descriptionLabel(>=60)]->=25-[button]->=50-[cancelButton]-36-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views];
    [view addConstraints:VLayoutConstraints];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    // Horizontal
    [descriptionLabel addConstraint:[NSLayoutConstraint constraintWithItem:descriptionLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:273]];
    //[view addConstraint:[NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:descriptionLabel attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    //[view addConstraint:[NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:descriptionLabel attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    //[view addConstraint:[NSLayoutConstraint constraintWithItem:descriptionLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:titleLabel attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    
    [titleLabel.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
    
    // Add center button margin constraints for compact devices?
    

}

@end
