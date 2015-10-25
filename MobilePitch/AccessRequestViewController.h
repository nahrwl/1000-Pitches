//
//  AccessRequestViewController.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/24/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AccessRequestViewControllerDelegate <NSObject>

- (void)updateAuthorizationStatusForCam:(BOOL)cam andMicrophone:(BOOL)microphone;

@end

@interface AccessRequestViewController : UIViewController

@property (weak, nonatomic) id<AccessRequestViewControllerDelegate> delegate;

@end
