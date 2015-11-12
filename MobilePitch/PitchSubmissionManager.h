//
//  PitchSubmissionManager.h
//  MobilePitch
//
//  Created by Nathan Wallace on 11/1/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@class VideoSubmission;

@interface PitchSubmissionManager : AFHTTPSessionManager <NSCoding>

+ (instancetype)sharedManager;

- (void)queueVideoSubmission:(VideoSubmission *)submission;
- (void)resume;
- (void)stop;

- (void)serializeObjectToDefaultFile;

@property (nonatomic, copy) void (^savedCompletionHandler)(void);

@end
