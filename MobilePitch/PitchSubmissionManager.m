//
//  PitchSubmissionManager.m
//  MobilePitch
//
//  Created by Nathan Wallace on 11/1/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "PitchSubmissionManager.h"
#import "VideoSubmission.h"

// NSCoding keys
#define kQueuedVideoSubmissionsSerializationKey @"queuedVideoSubmissions"
#define kShouldProcessQueueSerializationKey @"shouldProcessQueue"
#define kCurrentVideoSubmissionSerializationKey @"currentVideoSubmission"

static NSString * const kBackgroundSessionIdentifier = @"org.sparksc.MobilePitch.backgroundsession";
static NSString * baseURL = @"http://52.4.50.233";

@interface PitchSubmissionManager ()

@property (strong, nonatomic) NSMutableArray<VideoSubmission *> *queuedVideoSubmissions;

// Track if the manager should continue uploading or not
@property (nonatomic) BOOL shouldProcessQueue;

// Currently uploading status
- (BOOL)isUploading;

// Current video submission
@property (strong, nonatomic) VideoSubmission *currentVideoSubmission;

// Data response containing the video URL on the server
@property (strong, nonatomic) NSMutableData *responseData;

@end

@implementation PitchSubmissionManager

#pragma mark Instance Configuration

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
    self = [super initWithBaseURL:[NSURL URLWithString:baseURL] sessionConfiguration:configuration];
    //self = [super initWithBaseURL:[NSURL URLWithString:baseURL]];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)configure {
    self.shouldProcessQueue = YES;
    
    [self configureSerializers];
    [self configureServerResponse];
    [self configureUploadFinished];              // when upload done
    [self configureBackgroundSessionFinished];   // when entire background session done, call completion handler
}

- (void)configureSerializers {
    // Generate a generic AFHTTPRequestSerializer for the headers
    AFHTTPRequestSerializer *requestSerializer = [[AFHTTPRequestSerializer alloc] init];
    [requestSerializer setValue:@"lk2108hio20ascnwb128h398hqln39" forHTTPHeaderField:@"Authorization-Token"];
    [requestSerializer setValue:@"" forHTTPHeaderField:@"DEVICE-ID"];
    
    self.requestSerializer = requestSerializer;
}

- (void)configureServerResponse {
    typeof(self) __weak weakSelf = self;
    
    [self setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response)
    {
        weakSelf.responseData = [[NSMutableData alloc] init];
        return NSURLSessionResponseAllow;
    }];
    
    [self setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data)
    {
        [weakSelf.responseData appendData:data];
    }];
}

- (void)configureUploadFinished
{
    typeof(self) __weak weakSelf = self;
    
    [self setDownloadTaskDidFinishDownloadingBlock:^NSURL * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, NSURL * _Nonnull location) {
        // Read the downloaded data
        weakSelf.responseData = [[NSData dataWithContentsOfURL:location] mutableCopy];
        return nil;
    }];
    
    [self setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        NSLog(@"Upload task completed.");
        
        if (error) {
            // handle error here, e.g.,
            
            NSLog(@"%@: %@", [task.originalRequest.URL lastPathComponent], error);
            
            // Requeue the current video submission
            if (weakSelf.currentVideoSubmission) {
                [weakSelf queueVideoSubmission:weakSelf.currentVideoSubmission];
                weakSelf.currentVideoSubmission = nil;
            }
        }
        
        // handle the response data
        if (weakSelf.responseData) {
            NSError *dataSerializationError = nil;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:weakSelf.responseData options:0 error:&dataSerializationError];
            
            if (dataSerializationError) {
                NSLog(@"Error serializing returned data: %@",dataSerializationError.localizedDescription);
                NSLog(@"String contents of data: %@",[[NSString alloc] initWithData:weakSelf.responseData encoding:NSUTF8StringEncoding]);
            }
            
            weakSelf.responseData = nil;
            
            // Handle response
            if (response) {
                NSLog(@"%@",response);
            }
        }
        
        // move on to the next element
        [weakSelf checkUploadStatus];
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

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [aDecoder decodeObjectForKey:kQueuedVideoSubmissionsSerializationKey];
        [aDecoder decodeBoolForKey:kShouldProcessQueueSerializationKey];
        
        [self configure];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.queuedVideoSubmissions forKey:kQueuedVideoSubmissionsSerializationKey];
    [aCoder encodeBool:self.shouldProcessQueue forKey:kShouldProcessQueueSerializationKey];
}

#pragma mark Properties

- (NSMutableArray<VideoSubmission *> *)queuedVideoSubmissions {
    if (!_queuedVideoSubmissions) {
        _queuedVideoSubmissions = [NSMutableArray array];
    }
    return _queuedVideoSubmissions;
}

- (BOOL)isUploading {
    return self.tasks.count > 0;
}

#pragma mark Queue

- (void)queueVideoSubmission:(VideoSubmission *)submission {
    if (submission) {
        [self.queuedVideoSubmissions addObject:submission];
        [self checkUploadStatus];
    }
}

- (VideoSubmission *)dequeueVideoSubmissionAtIndex:(NSUInteger)index {
    VideoSubmission *submission = [self.queuedVideoSubmissions objectAtIndex:index];
    [self.queuedVideoSubmissions removeObjectAtIndex:index];
    return submission;
}

#pragma mark Upload

- (void)resume {
    self.shouldProcessQueue = YES;
    [self checkUploadStatus];
}

- (void)stop {
    self.shouldProcessQueue = NO;
}

- (void)checkUploadStatus {
    if (self.shouldProcessQueue && !self.isUploading) {
        // Process the next video!
        [self backgroundUploadNextVideo];
    }
}

// Upload the VideoSubmission at index 0 of the videos submission queue, if any.
- (void)backgroundUploadNextVideo {
    if (self.queuedVideoSubmissions.count > 0) {
        // Upload the VideoSubmission at index 0
        
        // Dequeue and save the video submission
        self.currentVideoSubmission = [self dequeueVideoSubmissionAtIndex:0];
        
        // Generate the NSURLSessionDataTask for the current video submission
        NSURLSessionDownloadTask *task = [self uploadTaskForVideoSubmission:self.currentVideoSubmission];
        
        // Execute the task
        //[task resume];
    }
}

- (NSURLSessionDownloadTask *)uploadTaskForVideoSubmission:(VideoSubmission *)submission {
    NSURL *requestUrl = [NSURL URLWithString:@"/api/upload-video" relativeToURL:self.baseURL];
    
    NSError *errorFormAppend;
    NSError *errorRequest;
    
    NSMutableURLRequest *temprequest = [self.requestSerializer
                                    multipartFormRequestWithMethod:@"POST"
                                    URLString:requestUrl.absoluteString
                                    parameters:nil
                                    constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                        NSError *error = errorFormAppend;
                                        [formData appendPartWithFileURL:submission.fileURL
                                                                   name:@"file"
                                                               fileName:@"file"
                                                               mimeType:@"video/quicktime"
                                                                  error:&error];
                                    }
                                    error:&errorRequest];
    
    NSString* tmpFilename = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
    NSURL* tmpFileUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpFilename]];
    NSLog(@"%@",tmpFileUrl.absoluteString);
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMultipartFormRequest:temprequest writingStreamContentsToFile:tmpFileUrl completionHandler:^(NSError * _Nullable error) {
        NSURLSessionUploadTask *task = [self uploadTaskWithRequest:temprequest fromFile:tmpFileUrl progress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            // Cleanup: remove temporary file.
            [[NSFileManager defaultManager] removeItemAtURL:tmpFileUrl error:nil];
            
            // Do something with the result.
            if (error) {
                NSLog(@"Error: %@", error);
            } else {
                NSLog(@"Success: %@", responseObject);
            }
        }];
        [task resume];
    }];
    
    
    //NSURLSessionDownloadTask *task = [self downloadTaskWithRequest:request progress:nil destination:nil completionHandler:nil];
    
    /*NSURLSessionUploadTask *task = [self uploadTaskWithStreamedRequest:request progress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"RESPONSE OBJECT: %@",responseObject);
    }];*/
    
    return nil;
}

@end