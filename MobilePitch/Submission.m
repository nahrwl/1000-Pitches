//
//  Submission.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/10/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import "Submission.h"

#import <AFNetworking/AFNetworking.h>

#define kFileURLKey @"kFileURLKey"
#define kFormDataKey @"kFormDataKey"
#define kServerURLKey @"kServerURLKey"
#define kUploadStateKey @"kUploadStateKey"

static NSString * kBaseURL = @"http://1kp-api-dev.us-west-1.elasticbeanstalk.com";

@interface Submission ()

@property (nonatomic, readwrite) SubmissionUploadState uploadState;
@property (strong, nonatomic, readwrite) AFHTTPSessionManager *sessionManager;

@property (nonatomic, copy) CallbackBlock successBlock;
@property (nonatomic, copy) CallbackBlock failureBlock;
@property (nonatomic, copy) CallbackBlock seriousFailureBlock;

- (void)processVideoUploadResponse:(id)responseData;

@end

@implementation Submission

#pragma mark Initialization

- (instancetype)init {
    return [self initWithFile:[NSURL URLWithString:@""]];
}

- (instancetype)initWithFile:(NSURL *)fileURL
{
    if (self = [super init]) {
        _fileName = [fileURL lastPathComponent];
        _uploadState = SubmissionUploadStateNotUploaded;
        _serverURL = nil;
        _formData = nil;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSString *fileName = [(NSURL *)[aDecoder decodeObjectForKey:kFileURLKey] lastPathComponent];
        _fileName = fileName ? fileName : @"";
        
        NSNumber *tempState = [aDecoder decodeObjectForKey:kUploadStateKey];
        _uploadState = tempState ? [tempState integerValue] : SubmissionUploadStateNotUploaded;
        
        NSURL *serverURL = [aDecoder decodeObjectForKey:kServerURLKey];
        _serverURL = serverURL;
        
        NSDictionary *formData = [aDecoder decodeObjectForKey:kFormDataKey];
        _formData = formData;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.fileName forKey:kFileURLKey];
    [aCoder encodeObject:@(self.uploadState) forKey:kUploadStateKey];
    [aCoder encodeObject:self.serverURL forKey:kServerURLKey];
    [aCoder encodeObject:self.formData forKey:kFormDataKey];
}

#pragma mark Public API

- (void)submit:(CallbackBlock _Nullable)success
       failure:(CallbackBlock _Nullable)failure
    corruption:(CallbackBlock _Nullable)seriousFailure
{
    if (self.uploadState == SubmissionUploadStateVideoUploading || self.uploadState == SubmissionUploadStateFormUploading)
    {
        // Video is currently uploading
        NSLog(@"Video or form is currently uploading, will not be submitting right now.");
    }
    else if (!self.serverURL)
    {
        // Save the callback blocks
        self.successBlock = success;
        self.failureBlock = failure;
        self.seriousFailureBlock = seriousFailure;
        
        // Submit the video
        [self uploadVideo];
    }
    else if (self.serverURL && self.formData)
    {
        // Save the callback blocks
        self.successBlock = success;
        self.failureBlock = failure;
        self.seriousFailureBlock = seriousFailure;
        
        // Submit the form
        [self uploadForm];
    }
}

#pragma mark - Private

- (AFHTTPSessionManager *)sessionManager
{
    if (!_sessionManager){
        AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _sessionManager = manager;
    }
    return _sessionManager;
}

#pragma mark Video

- (void)uploadVideo
{
    typeof(self) __weak weakSelf = self;
    
    NSURL *fileURL = [self getFileURLForName:self.fileName];
    
    NSError *reachableError = nil;
    [[self getFileURLForName:self.fileName] checkResourceIsReachableAndReturnError:&reachableError];
    
    if (reachableError)
    {
        // Uh oh, it's not reachable
        // Perhaps remove this submission then
        self.seriousFailureBlock();
        
        NSLog(@"Saved video file does not exist. %@",reachableError.localizedDescription);
    }
    else
    {
        NSURL *requestUrl = [NSURL URLWithString:@"/api/upload-video" relativeToURL:[NSURL URLWithString:kBaseURL]];
        
        __block NSError *errorFormAppend;
        NSError *errorRequest;
        
        NSMutableURLRequest *temprequest = [[self createRequestSerializer]
                                            multipartFormRequestWithMethod:@"POST"
                                            URLString:requestUrl.absoluteString
                                            parameters:nil
                                            constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                [formData appendPartWithFileURL:fileURL
                                                                           name:@"file"
                                                                       fileName:@"file"
                                                                       mimeType:@"video/quicktime"
                                                                          error:&errorFormAppend];
                                            }
                                            error:&errorRequest];
        if (errorFormAppend) {
            NSLog(@"Error appending file to body: %@",errorFormAppend.localizedDescription);
            NSLog(@"Video File URL: %@", [fileURL absoluteString]);
            
            // Purge the bad request... :(
            self.failureBlock();
        } else {
            
            // Update the upload status
            self.uploadState = SubmissionUploadStateVideoUploading;
            
            NSURLSessionUploadTask *uploadTask;
            uploadTask = [self.sessionManager
                          uploadTaskWithStreamedRequest:temprequest
                          progress:^(NSProgress * _Nonnull uploadProgress) {
                              // This is not called back on the main queue.
                              // You are responsible for dispatching to the main queue for UI updates
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  //Update the progress view
                                  //[progressView setProgress:uploadProgress.fractionCompleted];
                              });
                          }
                          completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                              if (error) {
                                  NSLog(@"Error: %@", error);
                                  weakSelf.uploadState = SubmissionUploadStateNotUploaded;
                                  self.failureBlock();
                              } else {
                                  // Set the uploaded state before processing the video response
                                  weakSelf.uploadState = SubmissionUploadStateVideoUploaded;
                                  [weakSelf processVideoUploadResponse:responseObject];
                              }
                          }];
            
            [uploadTask resume];
        }
    }
}

- (void)processVideoUploadResponse:(id)responseObject
{
    typeof(self) __weak weakSelf = self;
    
    // Handle response
    if (responseObject) {
        NSLog(@"%@",responseObject);
        
        NSString *newURL = responseObject[@"video_url"];
        if (newURL && ![newURL isEqualToString:@""]) {
            // All set!
            weakSelf.serverURL = [NSURL URLWithString:newURL];
            
            // Tell the object to submit again to try upload the form
            [weakSelf uploadForm];
        }
        else {
            weakSelf.uploadState = SubmissionUploadStateNotUploaded;
        }
        
    }
    else
    {
        weakSelf.uploadState = SubmissionUploadStateNotUploaded;
    }
}

#pragma mark Form

- (void)uploadForm
{
    typeof(self) __weak weakSelf = self;
    
    if (![self formIsValid])
    {
        NSLog(@"Form data is not valid! Not uploading.");
    }
    else
    {
        
        // Modify the inputted dictionary
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:self.formData];
        [parameters setObject:[self.serverURL absoluteString] forKey:@"video_url"];
        
        AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:kBaseURL]];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        // Really trivial and pretty much useless "security..."
        [manager.requestSerializer setValue:@"lk2108hio20ascnwb128h398hqln39" forHTTPHeaderField:@"Authorization-Token"];
        
        // Some unique device-value. What used to be a UDID. Just for tracking device useage
        [manager.requestSerializer setValue:@"" forHTTPHeaderField:@"DEVICE-ID"];
        
        
        // Update the upload state
        self.uploadState = SubmissionUploadStateFormUploading;
        
        // Upload the form data
        [manager POST:@"/api/pitch"
           parameters:parameters
             progress:^(NSProgress * _Nonnull uploadProgress)
         {
             // Nothing here for now
         }
              success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
         {
             NSLog(@"JSON: %@", responseObject);
             //here is place for code executed in success case
             
             if ([(NSString *)(responseObject[@"status"]) isEqualToString: @"success"])
             {
                 NSLog(@"Success!");
                 
                 weakSelf.uploadState = SubmissionUploadStateUploaded;
                 
                 // return yes
                 self.successBlock();
             }
             else
             {
                 // Reset to the video uploaded states
                 weakSelf.uploadState = SubmissionUploadStateVideoUploaded;
                 
                 // Callback
                 self.failureBlock();
             }
             
             
         }
              failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
         {
             //here is place for code executed in error case
             NSLog(@"Error: %@", [error localizedDescription]);
             
             // Reset to the video uploaded states
             weakSelf.uploadState = SubmissionUploadStateVideoUploaded;
             
             // Callback
             self.failureBlock();
         }];
    }
}

#pragma mark Helpers

- (AFHTTPRequestSerializer *)createRequestSerializer
{
    // Generate a generic AFHTTPRequestSerializer for the headers
    AFHTTPRequestSerializer *requestSerializer = [[AFHTTPRequestSerializer alloc] init];
    [requestSerializer setValue:@"lk2108hio20ascnwb128h398hqln39" forHTTPHeaderField:@"Authorization-Token"];
    [requestSerializer setValue:@"" forHTTPHeaderField:@"DEVICE-ID"];
    
    return requestSerializer;
}

- (bool)formIsValid
{
    return self.formData != nil && self.serverURL != nil;
}

- (NSURL *)getFileURLForName:(NSString *)file
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSURL *fileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:file]];
    return fileURL;
}

@end
