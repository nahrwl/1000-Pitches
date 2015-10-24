//
//  CameraViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/24/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "CameraViewController.h"
#import "AccessRequestViewController.h"

#define kRecordButtonAnimationDuration 0.2f

@interface CameraViewController ()

@property (weak, nonatomic) UILabel *timerLabel;

@property (weak, nonatomic) UIButton *recordButton;
@property (weak, nonatomic) NSLayoutConstraint *recordButtonHeightConstraint;
@property (weak, nonatomic) NSLayoutConstraint *recordButtonWidthConstraint;

- (void)recordButtonTapped:(UIButton *)sender;
- (void)toggleRecording;

- (void)backButtonTapped:(UIButton *)sender;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

}

- (void)viewDidAppear:(BOOL)animated {
    double delayInSeconds = 1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //code to be executed on the main queue after delay
        [self presentViewController:[[AccessRequestViewController alloc] init] animated:YES completion:nil];
    });
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backButtonTapped:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)recordButtonTapped:(UIButton *)sender {
    //NSLog(@"Record button tapped");
    [self toggleRecording];
}

- (void)toggleRecording {
    static BOOL currentlyRecording = NO;
    if (!currentlyRecording) {
        // Start recording
        //NSLog(@"Start recording");
        // Animate start -> stop button change
        [self.view layoutIfNeeded];
        self.recordButtonHeightConstraint.constant = 28;
        self.recordButtonWidthConstraint.constant = 28;
        [UIView animateWithDuration:kRecordButtonAnimationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.fromValue = @(self.recordButton.layer.cornerRadius);
        animation.toValue = @(4);
        animation.duration = kRecordButtonAnimationDuration - 0.05;
        [self.recordButton.layer setCornerRadius:4];
        [self.recordButton.layer addAnimation:animation forKey:@"cornerRadius"];
        
        currentlyRecording = YES;
        
    } else {
        // Stop recording
        //NSLog(@"Stop recording");
        // Animate stop -> start button change
        [self.view layoutIfNeeded];
        self.recordButtonHeightConstraint.constant = 50;
        self.recordButtonWidthConstraint.constant = 50;
        [UIView animateWithDuration:kRecordButtonAnimationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.fromValue = @(self.recordButton.layer.cornerRadius);
        animation.toValue = @(25);
        animation.duration = kRecordButtonAnimationDuration - 0.1;
        animation.beginTime = CACurrentMediaTime() + 0.05f;
        
        double delayInSeconds = 0.06;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //code to be executed on the main queue after delay
            [self.recordButton.layer setCornerRadius:25];
        });
        [self.recordButton.layer addAnimation:animation forKey:@"cornerRadius"];
        
        currentlyRecording = NO;
    }
}

- (void)loadView {
    UIView *view = [[UIView alloc] init];
    self.view = view;
    
    view.backgroundColor = [UIColor grayColor];
    
    // Top view
    UIView *topView = [[UIView alloc] init];
    topView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:topView];
    // Appearance
    topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.35];
    topView.opaque = NO;
    
    // Top view timer label
    UILabel *timerLabel = [[UILabel alloc] init];
    timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [topView addSubview:timerLabel];
    self.timerLabel = timerLabel;
    // Appearance
    timerLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightLight];
    timerLabel.textColor = [UIColor whiteColor];
    // Content
    timerLabel.text = @"00:00";
    
    // Top view AUTOLAYOUT
    [topView addConstraint:[NSLayoutConstraint constraintWithItem:timerLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:topView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[timerLabel]-10-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(timerLabel)]];
    
    // Bottom views
    UIView *bottomView = [[UIView alloc] init];
    bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bottomView];
    // Appearance
    bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.35];
    bottomView.opaque = NO;
    
    // Bottom view record button decal
    UIImageView *recordButtonDecal = [[UIImageView alloc] init];
    recordButtonDecal.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomView addSubview:recordButtonDecal];
    // Appearance
    [recordButtonDecal setImage:[UIImage imageNamed:@"record-button-decal"]];
    
    // Bottom view record button
    UIButton *recordButton = [[UIButton alloc] init];
    recordButton.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomView addSubview:recordButton];
    self.recordButton = recordButton;
    [recordButton addTarget:self action:@selector(recordButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    // Appearance
    recordButton.backgroundColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    recordButton.layer.cornerRadius = 25.0f; // make it a circle!
    // Size
    NSLayoutConstraint *recordButtonHeightConstraint = [NSLayoutConstraint constraintWithItem:recordButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50.0f];
    [recordButton addConstraint:recordButtonHeightConstraint];
    self.recordButtonHeightConstraint = recordButtonHeightConstraint;
    
    NSLayoutConstraint *recordButtonWidthConstraint = [NSLayoutConstraint constraintWithItem:recordButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50.0f];
    [recordButton addConstraint:recordButtonWidthConstraint];
    self.recordButtonWidthConstraint = recordButtonWidthConstraint;
    
    // Bottom view back button
    UIButton *backButton = [[UIButton alloc] init];
    backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomView addSubview:backButton];
    [backButton addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    // Appearance
    [backButton setImage:[UIImage imageNamed:@"left arrow"] forState:UIControlStateNormal];
    
    // Bottom view AUTOLAYOUT
    [recordButton.centerXAnchor constraintEqualToAnchor:bottomView.centerXAnchor].active = YES;
    [recordButton.centerYAnchor constraintEqualToAnchor:bottomView.centerYAnchor].active = YES;
    
    [recordButtonDecal.centerXAnchor constraintEqualToAnchor:bottomView.centerXAnchor].active = YES;
    [recordButtonDecal.centerYAnchor constraintEqualToAnchor:bottomView.centerYAnchor].active = YES;
    
    [backButton.centerYAnchor constraintEqualToAnchor:bottomView.centerYAnchor].active = YES;
    [bottomView addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:bottomView attribute:NSLayoutAttributeLeading multiplier:1 constant:26]];
    
    // Notification view
    UIView *notificationView = [[UIView alloc] init];
    notificationView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:notificationView];
    // Appearance
    notificationView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.60];
    
    // Notification label
    UILabel *notificationLabel = [[UILabel alloc] init];
    notificationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [notificationView addSubview:notificationLabel];
    // Appearance
    notificationLabel.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"TAP TO BEGIN"];
    [attributedString addAttribute:NSKernAttributeName
                             value:@(1.0f)
                             range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular]
                             range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:[UIColor whiteColor]
                             range:NSMakeRange(0, attributedString.length)];
    [notificationLabel setAttributedText:attributedString];
    
    // Notification view AUTOLAYOUT
    [notificationView addConstraint:[NSLayoutConstraint constraintWithItem:notificationLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:notificationView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [notificationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[notificationLabel]-6-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(notificationLabel)]];
    
    // AUTOLAYOUT
    NSDictionary *views = NSDictionaryOfVariableBindings(topView,notificationView,bottomView);
    
    [topView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
    [topView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
    [topView.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
    
    NSArray *bottomVLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[notificationView][bottomView(97)]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views];
    [view addConstraints:bottomVLayoutConstraints];
    
    [notificationView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
    [notificationView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
    
    [bottomView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
    [bottomView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
    
    
}

@end
