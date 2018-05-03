//
//  SubmissionManager.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/10/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SubmissionStatusDelegate

- (void)stateDidChange;

@end

@interface SubmissionManager : NSObject <NSCoding>

@property (weak, nonatomic) id<SubmissionStatusDelegate> delegate;

+ (instancetype)sharedManager;
- (void)serializeObjectToDefaultFile;

- (void)openSubmissionWithVideo:(NSURL *)fileURL;
- (void)submitCurrentSubmissionWithFormData:(NSDictionary *)formData;
- (void)cancelCurrentSubmission;
- (void)checkUploadStatus;

- (NSArray *)getQueuedSubmissions;
- (NSArray *)getAllSubmissions;

@end

