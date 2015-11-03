//
//  PitchSubmissionManager.m
//  MobilePitch
//
//  Created by Nathan Wallace on 11/1/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "PitchSubmissionManager.h"

static NSString * const kBackgroundSessionIdentifier = @"org.sparksc.MobilePitch.backgroundsession";

@implementation PitchSubmissionManager

+ (instancetype)sharedManager
{
    static id sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundSessionIdentifier];
    self = [super initWithSessionConfiguration:configuration];
    if (self) {
        [self configureUploadFinished];            // when download done, save file
        [self configureBackgroundSessionFinished];   // when entire background session done, call completion handler
    }
    return self;
}

- (void)configureUploadFinished
{
    [self setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        if (error) {
            // handle error here, e.g.,
            
            NSLog(@"%@: %@", [task.originalRequest.URL lastPathComponent], error);
        }
    }];
}

- (void)configureBackgroundSessionFinished
{
    typeof(self) __weak weakSelf = self;
    
    [self setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        if (weakSelf.savedCompletionHandler) {
            weakSelf.savedCompletionHandler();
            weakSelf.savedCompletionHandler = nil;
        }
    }];
}

@end