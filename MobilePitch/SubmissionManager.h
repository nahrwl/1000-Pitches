//
//  SubmissionManager.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/10/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SubmissionManager : NSObject <NSCoding>

+ (instancetype)sharedManager;
- (void)serializeObjectToDefaultFile;

- (void)openSubmissionWithVideo:(NSURL *)fileURL;
- (void)submitCurrentSubmissionWithFormData:(NSDictionary *)formData;
- (void)cancelCurrentSubmission;
- (void)checkUploadStatus;

- (NSArray *)getQueuedSubmissions;

@end

