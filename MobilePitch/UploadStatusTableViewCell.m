//
//  UploadStatusTableViewCell.m
//  MobilePitch
//
//  Created by Nathan Wallace on 9/20/17.
//  Copyright © 2017 Spark Dev Team. All rights reserved.
//

#import "UploadStatusTableViewCell.h"

@implementation UploadStatusTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setStatus:(SubmissionUploadState)status {
    switch (status) {
        case SubmissionUploadStateNotUploaded:
            [self.statusImage setImage:[UIImage imageNamed:@"Not Uploaded"]];
            [self.activityIndicator stopAnimating];
            break;
        case SubmissionUploadStateFormUploading:
        case SubmissionUploadStateVideoUploaded:
        case SubmissionUploadStateVideoUploading:
            [self.statusImage setImage:nil];
            [self.activityIndicator startAnimating];
            break;
        case SubmissionUploadStateUploaded:
            [self.statusImage setImage:[UIImage imageNamed:@"Finished"]];
            [self.activityIndicator stopAnimating];
            break;
        case SubmissionUploadStateError:
            [self.statusImage setImage:[UIImage imageNamed:@"Error"]];
            [self.activityIndicator stopAnimating];
            break;
    }
}

@end
