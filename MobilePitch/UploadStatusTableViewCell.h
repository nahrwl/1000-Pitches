//
//  UploadStatusTableViewCell.h
//  MobilePitch
//
//  Created by Nathan Wallace on 9/20/17.
//  Copyright © 2017 Spark Dev Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Submission.h"

@interface UploadStatusTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (void)setStatus:(SubmissionUploadState)status;

@end
