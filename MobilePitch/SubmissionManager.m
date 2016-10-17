//
//  SubmissionManager.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/10/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import "SubmissionManager.h"
#import "Submission.h"

#import <AFNetworking/AFNetworking.h>

// Serialized singleton file name
#define kSerializedFileName @"MobilePitchObject"

// NSCoding keys
#define kQueuedSubmissionsSerializationKey @"queuedSubmissions"
#define kUploadingSubmissionKey @"kUploadingSubmissionKey"

// Fix common typo
#define Ni nil

// Later in the film...
#define Ekke_Ekke_Ekke_Ekke_Ptang_Zoo_Boing Ni

@interface SubmissionManager ()

// This Submission object is the current pitch the user is creating
@property (strong, nonatomic) Submission *buildingSubmission;

// This Submission object is the Submission currently being uploaded to the server
@property (strong, nonatomic) Submission *uploadingSubmission;

// This is a queue of complete, unsubmitted Submissions, if any
@property (strong, nonatomic) NSMutableArray<Submission *> *queuedSubmissions;

- (void)submitNextQueuedSubmission;
- (void)submitUploadingSubmission;
- (void)purgeUploadingSubmission;

@end

@implementation SubmissionManager

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


#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _queuedSubmissions = [[aDecoder decodeObjectForKey:kQueuedSubmissionsSerializationKey] mutableCopy];
        
        // Handle a saved uploading submission
        Submission *tempSubmission = [aDecoder decodeObjectForKey:kUploadingSubmissionKey];
        [tempSubmission resetUploadingState];
        if (tempSubmission)
        {
            if (tempSubmission.uploadState != SubmissionUploadStateUploaded)
            {
                // If it's not actually uploaded, requeue it
                [_queuedSubmissions addObject:tempSubmission];
            }
            else
            {
                // If it is indeed uploaded, purge it
                _uploadingSubmission = tempSubmission;
                [self purgeUploadingSubmission];
            }
        }
        _uploadingSubmission = nil;
        
        // Begin listening for changes in network connectivity
        [self configureNetworkReachabilityMonitoring];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.queuedSubmissions forKey:kQueuedSubmissionsSerializationKey];
    [aCoder encodeObject:self.uploadingSubmission forKey:kUploadingSubmissionKey];
}

- (void)serializeObjectToDefaultFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:kSerializedFileName];
    
    [NSKeyedArchiver archiveRootObject:self toFile:filePath];
}

#pragma mark Configuration

- (void)configureNetworkReachabilityMonitoring
{
    typeof(self) __weak weakSelf = self;
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN) {
            // Network is reachable
            [weakSelf submitNextQueuedSubmission];
        }
    }];
    // Note that this block will not be called unless the
    // reachablility manager is told to start monitoring.
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

#pragma mark Lazy Loading

- (NSMutableArray<Submission *> *)queuedSubmissions
{
    if (!_queuedSubmissions) {
        _queuedSubmissions = [NSMutableArray array];
    }
    return _queuedSubmissions;
}

#pragma mark Submissions

- (NSArray *)getQueuedSubmissions
{
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:self.queuedSubmissions];
    
    // Include the submission being uploaded to the server
    if (self.uploadingSubmission) {
        [tempArray insertObject:self.uploadingSubmission atIndex:0];
    }
    
    // Include the submission currently in progress
    if (self.buildingSubmission) {
        [tempArray insertObject:self.buildingSubmission atIndex:0];
    }
    return [tempArray copy];
}

- (void)openSubmissionWithVideo:(NSURL *)fileURL
{
    if (self.buildingSubmission)
    {
        NSLog(@"Something is unexpectedly stored in the building submission property! Discarding...");
        // Don't actually "cancel" the submission here
        // Just in case two submissions erroneously refer to the same video file
    }
    
    self.buildingSubmission = [[Submission alloc] initWithFile:fileURL];
}

- (void)submitCurrentSubmissionWithFormData:(NSDictionary *)formData
{
    // Add the form data to the building submission, completing it
    self.buildingSubmission.formData = formData;
    
    // Add the building submission to the submission queue
    [self.queuedSubmissions addObject:self.buildingSubmission];
    
    // End building this submission
    self.buildingSubmission = nil;
    
    // Check the queue status
    [self submitNextQueuedSubmission];
}

- (void)cancelCurrentSubmission
{
    self.buildingSubmission = nil;
}

- (void)checkUploadStatus
{
    [self submitNextQueuedSubmission];
}

#pragma mark - Private

- (void)submitUploadingSubmission
{
    typeof(self) __weak weakSelf = self;
    
    [self.uploadingSubmission submit:^
     {
         // Successful return
         
         // Purge the submission after completing successfully
         [weakSelf purgeUploadingSubmission];
         
         NSLog(@"Submission complete!");
         
         // Check if there's anything else to submit
         [self submitNextQueuedSubmission];
     }
                           failure:^
     {
         // Requeue the submission
         [weakSelf.queuedSubmissions addObject:weakSelf.uploadingSubmission];
         weakSelf.uploadingSubmission = nil;
         
     }
                        corruption:^
     {
         // Remove the files entirely
         [weakSelf purgeUploadingSubmission];
         NSLog(@"Critical error: Submission being deleted.");
     }];
}

- (void)submitNextQueuedSubmission
{
    if (self.uploadingSubmission)
    {
        // A submission is currently being uploaded
        NSLog(@"A submission is currently being uploaded. Deferring...");
    }
    // Else, dequeue the next submission
    else if (self.queuedSubmissions.count > 0)
    {
        self.uploadingSubmission = [self.queuedSubmissions objectAtIndex:0];
        [self.queuedSubmissions removeObjectAtIndex:0];
        
        // Submit it
        [self submitUploadingSubmission];
    }
}

- (void)purgeUploadingSubmission
{
    // Remove the file
    NSError *removeError;
    [[NSFileManager defaultManager] removeItemAtURL:[self getFileURLForName:self.uploadingSubmission.fileName] error:&removeError];
    
    if (removeError) {
        NSLog(@"Removing the video file failed!");
        NSLog(@"%@",[removeError localizedDescription]);
    }
    
    // Remove the uploading submission
    self.uploadingSubmission = nil;
}

#pragma mark Helpers

- (NSURL *)getFileURLForName:(NSString *)file
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSURL *fileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:file]];
    return fileURL;
}


@end
