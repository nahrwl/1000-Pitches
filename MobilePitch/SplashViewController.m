//
//  SplashViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/23/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "SplashViewController.h"
#import "CameraViewController.h"

@interface SplashViewController ()

- (void)pitchButtonTapped:(UIButton *)sender;

@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES];
    
    // Status bar color updates - tell the nav controller that the content is dark
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pitchButtonTapped:(UIButton *)sender {
    [self.navigationController pushViewController:[[CameraViewController alloc] init] animated:YES];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)loadView {
    // Setup the view
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor colorWithRed:0.286 green:0.561 blue:0.729 alpha:1];
    self.view = view;
    
    // Title text
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:titleLabel];
    // Title text formatting
    titleLabel.text = @"Welcome to";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor whiteColor];
    
    // 1000 pitches logo
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo"]];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:logo];
    
    // Header text
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:headerLabel];
    // Header text formatting
    headerLabel.text = @"It's simple:";
    headerLabel.textAlignment = NSTextAlignmentNatural;
    headerLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightSemibold];
    headerLabel.textColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    
    // List text
    UILabel *listLabel = [[UILabel alloc] init];
    listLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:listLabel];
    // List text formatting
    NSMutableAttributedString *listLabelAttributedString = [[NSMutableAttributedString alloc] initWithString:@"1. Think of an idea\n2. Record your pitch\n3. Win a free T-Shirt"];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 6;
    [listLabelAttributedString addAttribute:NSParagraphStyleAttributeName
                             value:paragraphStyle
                             range:NSMakeRange(0, listLabelAttributedString.length)];
    listLabel.attributedText = listLabelAttributedString;
    listLabel.numberOfLines = 3;
    listLabel.textAlignment = NSTextAlignmentNatural;
    listLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightLight];
    listLabel.textColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    listLabel.textColor = [UIColor whiteColor];
    
    // Button
    UIButton *button = [[UIButton alloc] init];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:button];
    // Button formatting
    button.backgroundColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    button.layer.cornerRadius = 8;
    // Button titleLabel formatting
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: @"I HAVE A PITCH"];
    [attributedString addAttribute:NSKernAttributeName
                             value:@(3.8f)
                             range:NSMakeRange(0, attributedString.length)];
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
    [button addTarget:self action:@selector(pitchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // AUTOLAYOUT
    NSDictionary *views = NSDictionaryOfVariableBindings(titleLabel, logo, headerLabel, listLabel, button);
    
    // Horizontal
    NSArray *horizontalButtonLayoutConstraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[button]-20-|"
                                            options:NSLayoutFormatAlignAllCenterY
                                            metrics:nil
                                              views:views];
    [view addConstraints:horizontalButtonLayoutConstraints];
    
    //[view addConstraint:[NSLayoutConstraint constraintWithItem:listLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:237]];
    
    // Vertical
    NSArray *verticalLayoutConstraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-57-[titleLabel]-39-[logo]-55-[headerLabel]-19-[listLabel]->=20@100-[button(48)]-20-|"
                                            options:NSLayoutFormatAlignAllCenterX
                                            metrics:nil
                                              views:views];
    [view addConstraints:verticalLayoutConstraints];
    
    // Button detail
    NSArray *arrowHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[arrow]-13-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"arrow":arrow}];
    NSArray *arrowVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[arrow]-15-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"arrow":arrow}];
    [button addConstraints:arrowHConstraints];
    [button addConstraints:arrowVConstraints];
    
}

@end
