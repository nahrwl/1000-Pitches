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
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;

// Actions
- (void)okButtonTapped;

@end

@implementation AccessRequestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    //NSLog(@"Width of titleLabel is: %f",self.titleLabel.frame.size.width);
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)okButtonTapped {
    [self.activityIndicator startAnimating];
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL cam ) {
        if (cam) {
            // Move on to Microphone
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL microphone) {
                [self dismissViewControllerAnimated:YES completion:^{
                    [self.delegate updateAuthorizationStatusForCam:cam andMicrophone:microphone];;
                }];
            }];
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                [self.delegate updateAuthorizationStatusForCam:cam andMicrophone:NO];
            }];
        }
        
    }];
}

- (void)cancelButtonTapped {
    [self dismissViewControllerAnimated:YES completion:^{
        if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized) {
            if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] == AVAuthorizationStatusAuthorized) {
                [self.delegate updateAuthorizationStatusForCam:YES andMicrophone:YES];
            } else {
                [self.delegate updateAuthorizationStatusForCam:YES andMicrophone:NO];
            }
        } else {
            [self.delegate updateAuthorizationStatusForCam:NO andMicrophone:NO];
        }
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
    descriptionLabel.text = @"1000 Pitches needs access to your camera and microphone to\nrecord your pitch.";
    descriptionLabel.numberOfLines = 0; //undefined number of lines
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
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
    [cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // Activity indicator
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:indicator];
    self.activityIndicator = indicator;
    // Appearance
    indicator.hidesWhenStopped = YES;
    
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
    
    // Activity Indicator
    
    // Layout guides
    UILayoutGuide *topLayoutGuide = [[UILayoutGuide alloc] init];
    UILayoutGuide *bottomLayoutGuide = [[UILayoutGuide alloc] init];
    [view addLayoutGuide:topLayoutGuide];
    [view addLayoutGuide:bottomLayoutGuide];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:topLayoutGuide attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:bottomLayoutGuide attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button][topLayoutGuide][indicator][bottomLayoutGuide][cancelButton]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(button, topLayoutGuide, indicator, bottomLayoutGuide, cancelButton)]];
    
    // Add center button margin constraints for compact devices?
    

}

@end
