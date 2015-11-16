//
//  VideoSubmissionManager.m
//  MobilePitch
//
//  Created by Nathan Wallace on 11/1/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "VideoSubmissionManager.h"
#import "VideoSubmission.h"
#import "FormSubmission.h"

// NSCoding keys
#define kQueuedVideoSubmissionsSerializationKey @"queuedVideoSubmissions"
#define kQueuedFormSubmissionsSerializationKey @"queuedFormSubmissions"
#define kShouldProcessQueueSerializationKey @"shouldProcessQueue"
#define kCurrentVideoSubmissionSerializationKey @"currentVideoSubmission"
#define kCurrentUniqueIdentifierSerializationKey @"currentUniqueIdentifier"

// Temp directory
#define kTemporaryFilePrefix @"PSMRequest"

// Serialized singleton file name
#define kSerializedFileName @"PSMObject"

static NSString * const kBackgroundSessionIdentifier = @"org.sparksc.MobilePitch.backgroundsession";
static NSString * baseURL = @"http://52.4.50.233";

@interface VideoSubmissionManager ()

@property (nonatomic, readwrite) NSUInteger currentUniqueIdentifier;

@property (strong, nonatomic) NSMutableArray<VideoSubmission *> *queuedVideoSubmissions;
@property (strong, nonatomic) NSMutableArray<FormSubmission *> *queuedFormSubmissions;

// Track if the manager should continue uploading or not
@property (nonatomic) BOOL shouldProcessQueue;

// Currently uploading status
@property (nonatomic, getter=isUploading) BOOL uploading;

// Current video submission
@property (strong, nonatomic) VideoSubmission *currentVideoSubmission;

// Data response containing the video URL on the server
@property (strong, nonatomic) NSMutableData *responseData;

- (void)setServerURL:(NSString *)url forIdentifier:(NSUInteger)identifier;

@end

@implementation VideoSubmissionManager

#pragma mark Instance Configuration

+ (instancetype)sharedManager
{
    static id sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:kSerializedFileName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            sharedMyManager = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        } else {
            sharedMyManager = [[self alloc] init];
        }
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
    _shouldProcessQueue = YES;
    
    if (_currentUniqueIdentifier <= 0) {
        _currentUniqueIdentifier = 1;
    }
    
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
        if (!weakSelf.responseData) {
            weakSelf.responseData = [[NSMutableData alloc] init];
        }
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
        
        // Clean up temporary files
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *directory = NSTemporaryDirectory();
        NSError *fileError = nil;
        for (NSString *file in [fm contentsOfDirectoryAtPath:directory error:&fileError]) {
            if ([file hasPrefix:kTemporaryFilePrefix]) {
                [fm removeItemAtPath:[directory stringByAppendingPathComponent:file] error:&fileError];
            }
        }
        
        if (error) {
            // handle error here, e.g.,
            
            NSLog(@"%@: %@", [task.originalRequest.URL lastPathComponent], error);
            
            // Requeue the current video submission
            if (weakSelf.currentVideoSubmission) {
                [weakSelf queueVideoSubmission:weakSelf.currentVideoSubmission];
            }
        }
        
        // handle the response data
        else if (weakSelf.responseData) {
            NSError *dataSerializationError = nil;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:weakSelf.responseData options:0 error:&dataSerializationError];
            
            if (dataSerializationError) {
                NSLog(@"Error serializing returned data: %@",dataSerializationError.localizedDescription);
                NSLog(@"String contents of data: %@",[[NSString alloc] initWithData:weakSelf.responseData encoding:NSUTF8StringEncoding]);
            }
            
            // Important, since the data needs to be reset for the next upload
            weakSelf.responseData = nil;
            
            // Handle response
            if (response) {
                NSLog(@"%@",response);
                
                NSString *newURL = response[@"video_url"];
                if (newURL && ![newURL isEqualToString:@""]) {
                    [weakSelf setServerURL:newURL forIdentifier:weakSelf.currentVideoSubmission.identifier];
                }
            }
        }
        
        weakSelf.currentVideoSubmission = nil;
        
        // Tell self that we are no longer uploading
        weakSelf.uploading = NO;
        
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
        [self configure];
        
        _queuedVideoSubmissions = [[aDecoder decodeObjectForKey:kQueuedVideoSubmissionsSerializationKey] mutableCopy];
        _queuedFormSubmissions = [[aDecoder decodeObjectForKey:kQueuedFormSubmissionsSerializationKey] mutableCopy];
        _shouldProcessQueue = [aDecoder decodeBoolForKey:kShouldProcessQueueSerializationKey];
        
        NSNumber *identifierNumber = [aDecoder decodeObjectForKey:kCurrentUniqueIdentifierSerializationKey];
        _currentUniqueIdentifier = identifierNumber ? identifierNumber.unsignedIntegerValue : 1;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.queuedVideoSubmissions forKey:kQueuedVideoSubmissionsSerializationKey];
    [aCoder encodeObject:self.queuedFormSubmissions forKey:kQueuedFormSubmissionsSerializationKey];
    [aCoder encodeBool:self.shouldProcessQueue forKey:kShouldProcessQueueSerializationKey];
    [aCoder encodeObject:@(self.currentUniqueIdentifier) forKey:kCurrentUniqueIdentifierSerializationKey];
}

- (void)serializeObjectToDefaultFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:kSerializedFileName];
    
    [NSKeyedArchiver archiveRootObject:self toFile:filePath];
}

#pragma mark Properties

- (NSMutableArray<VideoSubmission *> *)queuedVideoSubmissions {
    if (!_queuedVideoSubmissions) {
        _queuedVideoSubmissions = [NSMutableArray array];
    }
    return _queuedVideoSubmissions;
}

- (NSMutableArray<FormSubmission *> *)queuedFormSubmissions {
    if (!_queuedFormSubmissions) {
        _queuedFormSubmissions = [NSMutableArray array];
    }
    return _queuedFormSubmissions;
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

- (void)setFormData:(NSDictionary *)data forIdentifier:(NSUInteger)identifier {
    FormSubmission *submission = [self formSubmissionWithIdentifier:identifier];
    if (!submission) {
        submission = [[FormSubmission alloc] initWithIdentifier:identifier];
        [self.queuedFormSubmissions addObject:submission];
    }
    [submission setFormData:data];
    
    [self checkFormSubmissionWithIdentifier:identifier];
}

- (void)setServerURL:(NSString *)url forIdentifier:(NSUInteger)identifier {
    FormSubmission *submission = [self formSubmissionWithIdentifier:identifier];
    if (!submission) {
        submission = [[FormSubmission alloc] initWithIdentifier:identifier];
        [self.queuedFormSubmissions addObject:submission];
    }
    [submission setServerURL:url];
    
    [self checkFormSubmissionWithIdentifier:identifier];
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
        
        // Upload the video submission
        [self uploadVideoSubmission:self.currentVideoSubmission];
    }
}

- (void)uploadVideoSubmission:(VideoSubmission *)submission {
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
    
    NSString* tmpFilename = [NSString stringWithFormat:@"%@%f", kTemporaryFilePrefix, [NSDate timeIntervalSinceReferenceDate]];
    NSURL* tmpFileUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpFilename]];
    NSLog(@"%@",tmpFileUrl.absoluteString);
    
    [self.requestSerializer requestWithMultipartFormRequest:temprequest writingStreamContentsToFile:tmpFileUrl completionHandler:^(NSError * _Nullable error) {
        NSURLSessionUploadTask *task = [self uploadTaskWithRequest:temprequest fromFile:tmpFileUrl progress:nil completionHandler:nil];
        
        self.uploading = YES;
        [task resume];
    }];
}

- (void)checkFormSubmissionWithIdentifier:(NSUInteger)identifier {
    NSLog(@"Checking for submission: %lu",(unsigned long)identifier);
    FormSubmission *submission = [self formSubmissionWithIdentifier:identifier];
    if (submission && [submission isComplete]) {
        // It's ready to go, submit it.
        [submission submitWithCompletion:^(BOOL success) {
            // Remove the submission
            [self.queuedFormSubmissions removeObject:submission];
            if (!success) {
                // Add the submission to the end of the array if submission did not succeed
                [self.queuedFormSubmissions addObject:submission];
            }
        }];
    }
}

#pragma mark Helpers

- (FormSubmission *)formSubmissionWithIdentifier:(NSUInteger)identifier {
    NSIndexSet *indexSet = [self.queuedFormSubmissions indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        FormSubmission *submission = (FormSubmission *)obj;
        return submission.identifier == identifier;
    }];
    NSUInteger index = indexSet.firstIndex;
    return index != NSNotFound ? self.queuedFormSubmissions[index] : nil;
}

// A unique key representing the video data / form data pairing
- (NSUInteger)generateUniqueIdentifier {
    return self.currentUniqueIdentifier++;
}

@end