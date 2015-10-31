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
#define kVideoURLKey @"kVideoURLKey"

@interface PitchSubmissionController ()

// Enqueued Form Submissions
@property (nonatomic, readwrite) NSUInteger currentUniqueIdentifier;

// Structure for these two dictionaries is as follows:
// @{unique identifier : @{kDataKey : NSDictionary form, kVideoURLKey : the returned video URL NSString}}
@property (strong, nonatomic) NSMutableDictionary *queuedFormSubmissions;
// @{unique identifier : @{kDataKey : video NSURL}
@property (strong, nonatomic) NSMutableDictionary *queuedVideoSubmissions;

// These two properties are the current objects that are being uploaded
// On success, the object is set to nil. On failure, the object should be re-queued for submission
@property (strong, nonatomic) NSDictionary *currentFormSubmission;
@property (strong, nonatomic) NSURL *currentVideoSubmission;

// Private Methods
- (void)submitFormWithIdentifier:(NSUInteger)identifier completion:(void (^)(BOOL success))completion;
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
    if (videoURL) {
        [self.queuedVideoSubmissions setObject:@{kDataKey : videoURL} forKey:@(identifier)];
    } else {
        NSLog(@"Attempted to insert nil into videos submissions queue.");
    }
}

- (void)queueFormSubmissionWithDictionary:(NSDictionary *)formDictionary identifier:(NSUInteger)identifier {
    if (formDictionary) {
        NSMutableDictionary *existingDictionary = [NSMutableDictionary dictionaryWithDictionary:self.queuedFormSubmissions[@(identifier)]];
        
        if (!existingDictionary) {
            existingDictionary = [NSMutableDictionary dictionary];
        }
        
        [existingDictionary setObject:formDictionary forKey:kDataKey];
        [self.queuedFormSubmissions setObject:[existingDictionary copy]
                                       forKey:@(identifier)];
    } else {
        NSLog(@"Attempted to insert nil into form submissions queue.");
    }
}

- (NSDictionary *)dequeueFormSubmissionForIdentifier:(NSUInteger)identifier {
    NSDictionary *form = self.queuedFormSubmissions[@(identifier)];
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
                                         [self queueVideoResponseURL:videoURL forIdentifier:lowestIdentifier.integerValue];
                                         [self submitFormWithIdentifier:lowestIdentifier.integerValue
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
                [self submitFormWithIdentifier:lowestIdentifier.integerValue completion:^(BOOL success) {
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

- (void)queueVideoResponseURL:(NSString *)videoURL forIdentifier:(NSUInteger)identifier {
    if (videoURL && ![videoURL isEqualToString:@""]) {
        NSMutableDictionary *existingDictionary = [NSMutableDictionary dictionaryWithDictionary:self.queuedFormSubmissions[@(identifier)]];
        
        if (!existingDictionary) {
            existingDictionary = [NSMutableDictionary dictionary];
        }
        
        [existingDictionary setObject:videoURL forKey:kVideoURLKey];
        [self.queuedFormSubmissions setObject:[existingDictionary copy]
                                       forKey:@(identifier)];
    } else {
        NSLog(@"Attempted to insert nil or empty video URL into form submissions queue.");
    }
}

- (void)submitVideoWithIdentifier:(NSUInteger)identifier completion:(void (^)(NSString *videoURL))completion {
    NSURL *fileURL = [self dequeueVideoForIdentifier:identifier];
    
    if (fileURL) {
        self.currentVideoSubmission = fileURL;
        
        // Generate a generic AFHTTPRequestSerializer for the headers
        AFHTTPRequestSerializer *requestSerializer = [[AFHTTPRequestSerializer alloc] init];
        [requestSerializer setValue:@"lk2108hio20ascnwb128h398hqln39" forHTTPHeaderField:@"Authorization-Token"];
        [requestSerializer setValue:@"" forHTTPHeaderField:@"DEVICE-ID"];
        
        // Session manager for the POST request
        AFHTTPSessionManager *managerFromData = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseURL]];
        managerFromData.requestSerializer = requestSerializer;
        managerFromData.responseSerializer = [AFJSONResponseSerializer serializer];
        
        [managerFromData POST:@"/api/upload-video" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            
            // videoData is a < 30 MB NSData object encoded in the video/quicktime (.mov) format
            
            NSError *appendError;
            [formData appendPartWithFileURL:fileURL name:@"file" fileName:@"file" mimeType:@"video/quicktime" error:&appendError];
            
            if (appendError) {
                NSLog(@"Appending video file data to multipart POST request failed! Error: %@",[appendError localizedDescription]);
            }
            
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
            
            NSLog(@"Response: %@", responseObject);
            // Will get {'video_url':'http://wllwl'}
            
            // destroy the video submission
            self.currentVideoSubmission = nil;
            
            // Remove the file from the disk! Important!
            NSError *fileError;
            [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&fileError];
            if (fileError) {
                NSLog(@"Error removing file at URL %@: %@",[fileURL absoluteString],[fileError localizedDescription]);
            }
            
            // Callback with returned URL
            completion(responseObject[@"video_url"]);
            
        } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
            
            NSLog(@"Error: %@", [error localizedDescription]);
            
            // requeue the failed submission
            [self queueVideoAtURL:fileURL identifier:identifier];
            
            // reset the current video submission
            self.currentVideoSubmission = nil;
            
            // Callback with no response
            completion(nil);
            
        }];
    } else {
        NSLog(@"File URL was nil, could not submit video");
    }
}

- (void)submitFormWithIdentifier:(NSUInteger)identifier
                      completion:(void (^)(BOOL success))completion {
    
    NSDictionary *formSubmissionDictionary = [self dequeueFormSubmissionForIdentifier:identifier];
    
    NSDictionary *input = formSubmissionDictionary[kDataKey];
    NSString *videoURL = formSubmissionDictionary[kVideoURLKey];
    
    if (input && videoURL) {
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
            [self queueVideoResponseURL:videoURL forIdentifier:identifier];
            
            // reset the current form submission
            self.currentFormSubmission = nil;
            
            // return no
            completion(NO);
        }];
    } else {
        NSLog(@"Inputted form dictionary was nil. Not submitting.");
    }
}


@end
