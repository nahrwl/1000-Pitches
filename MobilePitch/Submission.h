//
//  Submission.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/10/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SubmissionUploadState)
{
    SubmissionUploadStateNotUploaded,
    SubmissionUploadStateVideoUploading,
    SubmissionUploadStateVideoUploaded,
    SubmissionUploadStateFormUploading,
    SubmissionUploadStateUploaded
};

typedef void (^CallbackBlock)(void);

@interface Submission : NSObject <NSCoding>

@property (strong, nonatomic, nonnull)  NSString *fileName;
@property (strong, nonatomic, nullable) NSURL *serverURL;
@property (strong, nonatomic, nullable) NSDictionary *formData;
@property (nonatomic, readonly)         SubmissionUploadState uploadState;

- (instancetype _Nullable)initWithFile:( NSURL * _Nonnull )fileURL NS_DESIGNATED_INITIALIZER;
- (instancetype _Nullable)initWithCoder:(NSCoder * _Nonnull)aDecoder NS_DESIGNATED_INITIALIZER;

- (void)submit:(CallbackBlock _Nullable)success failure:(CallbackBlock _Nullable)failure corruption:(CallbackBlock _Nullable)seriousFailure;
- (void)resetUploadingState;

- (bool)formIsValid;

@end
