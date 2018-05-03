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
#define kCreatedDateKey @"kCreatedDateKey"

static NSString * kBaseURL = @"http://1kp-api-2017.us-west-1.elasticbeanstalk.com";

static NSString * const kBackgroundSessionIdentifier = @"org.sparksc.MobilePitch.backgroundsession";

@interface Submission ()

@property (nonatomic, readwrite) SubmissionUploadState uploadState;
@property (strong, nonatomic, readwrite) AFHTTPSessionManager *sessionManager;

@property (nonatomic, copy) CallbackBlock successBlock;
@property (nonatomic, copy) CallbackBlock failureBlock;
@property (nonatomic, copy) CallbackBlock seriousFailureBlock;

// Background upload
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, copy, nonnull) void (^endBackgroundTask)(void);
- (void)configureBackgroundTaskEnd;

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
        _backgroundTask = UIBackgroundTaskInvalid;
        _createdDate = [NSDate date];
        
        [self configureBackgroundTaskEnd];
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
        
        NSDate *date = [aDecoder decodeObjectForKey:kCreatedDateKey];
        _createdDate = date ? date : [NSDate date];
        
        _backgroundTask = UIBackgroundTaskInvalid;
        
        [self configureBackgroundTaskEnd];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.fileName forKey:kFileURLKey];
    [aCoder encodeObject:@(self.uploadState) forKey:kUploadStateKey];
    [aCoder encodeObject:self.serverURL forKey:kServerURLKey];
    [aCoder encodeObject:self.formData forKey:kFormDataKey];
    [aCoder encodeObject:self.createdDate forKey:kCreatedDateKey];
}

- (void)configureBackgroundTaskEnd
{
    typeof(self) __weak weakSelf = self;
    
    self.endBackgroundTask = ^void()
    {
        if (self.backgroundTask != UIBackgroundTaskInvalid)
        {
            [[UIApplication sharedApplication] endBackgroundTask:weakSelf.backgroundTask];
            weakSelf.backgroundTask = UIBackgroundTaskInvalid;
        }
    };
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

- (void)resetUploadingState
{
    switch (self.uploadState) {
        case SubmissionUploadStateVideoUploading:
            self.uploadState = SubmissionUploadStateNotUploaded;
            break;
            
        case SubmissionUploadStateFormUploading:
            self.uploadState = SubmissionUploadStateVideoUploaded;
            break;
            
        default:
            break;
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
        self.uploadState = SubmissionUploadStateError;
        self.seriousFailureBlock();
        
        NSLog(@"Saved video file does not exist. %@",reachableError.localizedDescription);
    }
    else
    {
        // Begin a temporary background session
        // Request a little time after the app closes
        self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:kBackgroundSessionIdentifier expirationHandler:^
        {
            self.failureBlock();
            self.endBackgroundTask();
        }];
        
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
            self.endBackgroundTask();
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
                                  self.endBackgroundTask();
                              } else {
                                  // Set the uploaded state before processing the video response
                                  weakSelf.uploadState = SubmissionUploadStateVideoUploaded;
                                  [weakSelf processVideoUploadResponse:responseObject];
                                  // The background task will be ended in the form callback blocks
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
        NSString *token = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Auth Token"];
        [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization-Token"];
        
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
             // Important: End the background task
             self.endBackgroundTask();
             
         }
              failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
         {
             //here is place for code executed in error case
             NSLog(@"Error: %@", [error localizedDescription]);
             
             // Reset to the video uploaded states
             weakSelf.uploadState = SubmissionUploadStateVideoUploaded;
             
             // Callback
             self.failureBlock();
             
             self.endBackgroundTask();
         }];
    }
}

#pragma mark Helpers

- (AFHTTPRequestSerializer *)createRequestSerializer
{
    // Generate a generic AFHTTPRequestSerializer for the headers
    AFHTTPRequestSerializer *requestSerializer = [[AFHTTPRequestSerializer alloc] init];
    NSString *token = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Auth Token"];
    [requestSerializer setValue:token forHTTPHeaderField:@"Authorization-Token"];
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *deviceId = [[currentDevice identifierForVendor] UUIDString];
    [requestSerializer setValue:deviceId forHTTPHeaderField:@"DEVICE-ID"];
    
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
