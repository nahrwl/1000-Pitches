//
//  VideoSubmissionManager.h
//  MobilePitch
//
//  Created by Nathan Wallace on 11/1/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@class VideoSubmission;

@interface VideoSubmissionManager : AFHTTPSessionManager <NSCoding>

+ (instancetype)sharedManager;
- (NSUInteger)generateUniqueIdentifier;

- (void)queueVideoSubmission:(VideoSubmission *)submission;

- (void)setFormData:(NSDictionary *)data forIdentifier:(NSUInteger)identifier;

- (void)resume;
- (void)stop;

- (void)serializeObjectToDefaultFile;

@property (nonatomic, copy) void (^savedCompletionHandler)(void);

@end
