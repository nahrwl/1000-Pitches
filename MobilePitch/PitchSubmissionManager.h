//
//  PitchSubmissionManager.h
//  MobilePitch
//
//  Created by Nathan Wallace on 11/1/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@interface PitchSubmissionManager : AFHTTPSessionManager

+ (instancetype)sharedManager;

@property (nonatomic, copy) void (^savedCompletionHandler)(void);

@end
