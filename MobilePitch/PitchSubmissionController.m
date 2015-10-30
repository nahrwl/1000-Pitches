//
//  PitchSubmissionController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/28/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "PitchSubmissionController.h"
#import <AFNetworking/AFNetworking.h>

#define kDataKey @"kDataKey"
#define kBlockKey @"kBlockKey"

@interface PitchSubmissionController ()

// Enqueued Form Submissions
@property (nonatomic, readwrite) NSUInteger currentUniqueIdentifier;

// Structure for these two dictionaries is as follows:
// @{unique identifier : @{kDataKey : some video URL or NSDictionary form, kBlockKey : the completion block}}
@property (strong, nonatomic) NSMutableDictionary *queuedFormSubmissions;
@property (strong, nonatomic) NSMutableDictionary *queuedVideoSubmissions;

// These two properties are the current objects that are being uploaded
// On success, the object is set to nil. On failure, the object should be re-queued for submission
@property (strong, nonatomic) NSDictionary *currentFormSubmission;
@property (strong, nonatomic) NSData *currentVideoSubmission;

// Private Methods
- (void)submitFormWithIdentifier:(NSUInteger)identifier forVideoURL:(NSString *)videoURL completion:(void (^)(BOOL success))completion;
- (void)submitVideoWithIdentifier:(NSUInteger)identifier completion:(void (^)(NSString *videoURL))completion;

@end

static NSString *baseURL = @"http://52.4.50.233";

@implementation PitchSubmissionController

#pragma mark Creating PitchSubmissionController instances

// PitchSubmissionController is a singleton class for the purposes
// of access from all of the view controllers. I have no idea if
// this practice is still standard or what.
+ (PitchSubmissionController *)sharedPitchSubmissionController {
    static PitchSubmissionController *_pitchSubmissionController;
    if (!_pitchSubmissionController) {
        _pitchSubmissionController = [[PitchSubmissionController alloc] init];
    }
    return _pitchSubmissionController;
}

// This is typically where -init would be overridden and replaced
// with a private implementation that replaces -init
// I do not feel the need to enforce singleton status at this point.
// Just nota bene for the future...
- (id)init {
    if (self = [super init]) {
        _currentUniqueIdentifier = 0;
        _queuedFormSubmissions = [NSMutableDictionary dictionary];
        _queuedVideoSubmissions = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark Pitch Submission

// A unique key representing the video data / form data pairing
- (NSUInteger)generateUniqueIdentifier {
    return self.currentUniqueIdentifier++;
}

- (void)queueVideoAtURL:(NSURL *)videoURL identifier:(NSUInteger)identifier {
    [self.queuedVideoSubmissions setObject:@{kDataKey : videoURL} forKey:@(identifier)];
}

- (void)queueFormSubmissionWithDictionary:(NSDictionary *)formDictionary identifier:(NSUInteger)identifier {
    [self.queuedFormSubmissions setObject:@{kDataKey : formDictionary} forKey:@(identifier)];
}

- (NSDictionary *)dequeueFormSubmissionForIdentifier:(NSUInteger)identifier {
    NSDictionary *form = self.queuedFormSubmissions[@(identifier)][kDataKey];
    [self.queuedFormSubmissions removeObjectForKey:@(identifier)];
    return form;
}

- (NSURL *)dequeueVideoForIdentifier:(NSUInteger)identifier {
    NSURL *video = self.queuedVideoSubmissions[@(identifier)][kDataKey];
    [self.queuedVideoSubmissions removeObjectForKey:@(identifier)];
    return video;
}

- (BOOL)startProcessingQueue {
    // If there's nothing already processing
    if (!self.currentFormSubmission && !self.currentVideoSubmission) {
        // Search to find the lowest index from the queued videos
        // Always start by uploading a video
        NSArray *identifiers = [self.queuedVideoSubmissions allKeys];
        
        if (identifiers.count > 0) {
            NSNumber *lowestIdentifier = @([self lowestQueuedIdentifierInArray:identifiers]);
            [self submitVideoWithIdentifier:lowestIdentifier.integerValue
                                 completion:^(NSString *videoURL) {
                                     if (videoURL) {
                                         [self submitFormWithIdentifier:lowestIdentifier.integerValue
                                                            forVideoURL:videoURL
                                                             completion:^(BOOL success) {
                                                                 if (success) {
                                                                     [self startProcessingQueue];
                                                                 } else {
                                                                     [self.delegate processingDidFail];
                                                                 }
                                                             }];
                                     } else {
                                         [self.delegate processingDidFail];
                                     }
                                 }];
        } else {
            // No videos to process
            // Process remaining forms then
            NSArray *identifiers = [self.queuedFormSubmissions allKeys];
            
            if (identifiers.count > 0) {
                NSNumber *lowestIdentifier = @([self lowestQueuedIdentifierInArray:identifiers]);
                [self submitFormWithIdentifier:lowestIdentifier.integerValue forVideoURL:@"" completion:^(BOOL success) {
                    if (success) {
                        [self startProcessingQueue];
                    } else {
                        [self.delegate processingDidFail];
                    }
                }];
            }
        }
        return YES;
    } else {
        // Something's processing, come back later
        return NO;
    }
}

#pragma mark Private Implementation

- (int)lowestQueuedIdentifierInArray:(NSArray *)identifiers {
    int idmin = [(NSNumber *)identifiers[0] intValue];
    for (int i = 0; i < identifiers.count; i++) {
        NSNumber *num = identifiers[i];
        int x = num.intValue;
        if (x < idmin) idmin = x;
    }
    return idmin;
}

- (void)submitVideoWithIdentifier:(NSUInteger)identifier completion:(void (^)(NSString *videoURL))completion {
    [self dequeueVideoForIdentifier:identifier];
    completion(@"http://s3.amazonaws.com/spark-onekp/691f2de1-b75e-44dd-8af4-70749c16c1ea");
    /*
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    AFHTTPSessionManager *managerFromData = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseURL]];
    [manager POST:@"/api/upload-video" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        NSDictionary *headers = @{@"Authorization-Token":@"lk2108hio20ascnwb128h398hqln39", @"DEVICE-ID":@""};
        [formData appendPartWithHeaders:headers body:nil];
        
        NSData *videoData;
        
        // videoData is a < 30 MB NSData object encoded in the video/quicktime (.mov) format
        [formData appendPartWithFileData:videoData name:@"file" fileName:@"file" mimeType:@"video/quicktime"];
        
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Response: %@", responseObject);
        // Will get {'video_url':'http://wllwl'}
        completion(responseObject[@"video_url"]);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        completion(nil);
    }];*/
}

- (void)submitFormWithIdentifier:(NSUInteger)identifier
                     forVideoURL:(NSString *)videoURL
                      completion:(void (^)(BOOL success))completion {
    
    NSDictionary *input = [self dequeueFormSubmissionForIdentifier:identifier];
    self.currentFormSubmission = input;

    // Modify the inputted dictionary
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:input];
    
    [parameters setObject:videoURL forKey:@"video_url"];
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseURL]];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // Really trivial and pretty much useless "security..."
    [manager.requestSerializer setValue:@"lk2108hio20ascnwb128h398hqln39" forHTTPHeaderField:@"Authorization-Token"];

    // Some unique device-value. What used to be a UDID. Just for tracking device useage
    //[manager.requestSerializer setValue:[self getUniqueDeviceIdentifierAsString] forHTTPHeaderField:@"DEVICE-ID"];
    [manager POST:@"/api/pitch" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSLog(@"JSON: %@", responseObject);
        //here is place for code executed in success case
        
        // destroy the form submission
        self.currentFormSubmission = nil;
        
        // return yes
        completion(YES);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        //here is place for code executed in error case
        
        NSLog(@"Error: %@", [error localizedDescription]);
        
        // requeue the failed submission
        [self queueFormSubmissionWithDictionary:input identifier:identifier];
        
        // return no
        completion(NO);
    }];
}


@end
