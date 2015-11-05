//
//  FinishedRecordingViewController.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/25/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FinishedRecordingViewControllerDelegate <NSObject>

- (void)submitVideo;
- (void)tryAgain;

@end

@interface FinishedRecordingViewController : UIViewController

@property (strong, nonatomic) NSString *finalTime;
@property (weak, nonatomic) UIViewController<FinishedRecordingViewControllerDelegate> *delegate;

@end
