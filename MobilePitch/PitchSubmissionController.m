//
//  PitchSubmissionController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/28/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "PitchSubmissionController.h"
#import <AFNetworking/AFNetworking.h>

// Dictionary keys
#define kIdentifierKey @"kIdentifierKey"
#define kDataKey @"kDataKey"
#define kVideoURLKey @"kVideoURLKey"

// NSCoding keys
#define kQueuedFormSubmissionsSerializationKey @"queuedFormSubmissions"
#define kQueuedVideoSubmissionsSerializationKey @"queuedVideoSubmissions"
#define kCurrentFormSubmissionSerializationKey @"currentFormSubmission"
#define kCurrentVideoSubmissionSerializationKey @"currentVideoSubmission"
#define kCurrentUniqueIdentifierSerializationKey @"currentUniqueIdentifier"

@interface PitchSubmissionController ()

// Enqueued Form Submissions
@property (nonatomic, readwrite) NSUInteger currentUniqueIdentifier;

// Structure for these two arrays is as follows:
// @[@{kIdentifierKey : unique identifier, kDataKey : NSDictionary form, kVideoURLKey : the returned video server URL NSString}, etc]
@property (strong, nonatomic) NSMutableArray *queuedFormSubmissions;
// @[@{kIdentifierKey : unique identifier, kDataKey : video local NSURL}, etc]
@property (strong, nonatomic) NSMutableArray *queuedVideoSubmissions;

// These two properties are the current objects that are being uploaded
// On success, the object is set to nil. On failure, the object should be re-queued for submission
@property (strong, nonatomic) NSDictionary *currentFormSubmission;
@property (strong, nonatomic) NSDictionary *currentVideoSubmission;

// Private Methods
- (void)submitFormWithIdentifier:(NSUInteger)identifier completion:(void (^)(BOOL success))completion;
- (void)submitVideoWithIdentifier:(NSUInteger)identifier completion:(void (^)(NSString *videoURL))completion;
- (NSUInteger)generateUniqueIdentifier;

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
- (instancetype)init {
    if (self = [super init]) {
        _currentUniqueIdentifier = 1; // Must not be 0
        _queuedFormSubmissions = [NSMutableArray array];
        _queuedVideoSubmissions = [NSMutableArray array];
    }
    return self;
}

#pragma mark NSCoding protocol

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [self init]) {
        _queuedVideoSubmissions = [coder decodeObjectForKey:kQueuedVideoSubmissionsSerializationKey];
        _queuedFormSubmissions = [coder decodeObjectForKey:kQueuedFormSubmissionsSerializationKey];
        
        _currentVideoSubmission = [coder decodeObjectForKey:kCurrentVideoSubmissionSerializationKey];
        _currentFormSubmission = [coder decodeObjectForKey:kCurrentFormSubmissionSerializationKey];
        
        _currentUniqueIdentifier = [(NSNumber *)[coder decodeObjectForKey:kCurrentUniqueIdentifierSerializationKey] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.queuedVideoSubmissions forKey:kQueuedVideoSubmissionsSerializationKey];
    [coder encodeObject:self.queuedFormSubmissions forKey:kQueuedFormSubmissionsSerializationKey];
    
    [coder encodeObject:self.currentFormSubmission forKey:kCurrentFormSubmissionSerializationKey];
    [coder encodeObject:self.currentVideoSubmission forKey:kCurrentVideoSubmissionSerializationKey];
    
    // Easier for me just to store the NSUInteger as an NSNumber
    [coder encodeObject:@(self.currentUniqueIdentifier) forKey:kCurrentUniqueIdentifierSerializationKey];
}

#pragma mark -
#pragma mark Pitch Submission

- (NSUInteger)queueVideoAtURL:(NSURL *)videoURL {
    if (videoURL) {
        NSUInteger identifier = [self generateUniqueIdentifier];
        [self.queuedVideoSubmissions addObject:@{kIdentifierKey : @(identifier), kDataKey : videoURL}];
        return identifier;
    }
    NSLog(@"Attempted to insert nil into videos submissions queue.");
    return 0; // Default id means error
}

- (void)queueFormSubmissionWithDictionary:(NSDictionary *)formDictionary identifier:(NSUInteger)identifier {
    if (formDictionary) {
        NSUInteger index = [self indexOfObjectWithIdentifier:identifier inArray:self.queuedFormSubmissions];
        
        NSMutableDictionary *existingDictionary = index != NSNotFound ? [NSMutableDictionary dictionaryWithDictionary:[self.queuedFormSubmissions objectAtIndex:index]] : [NSMutableDictionary dictionaryWithObject:@(identifier) forKey:kIdentifierKey];
        
        [existingDictionary setObject:formDictionary forKey:kDataKey];
        [self.queuedFormSubmissions setObject:existingDictionary atIndexedSubscript:index != NSNotFound ? index : self.queuedFormSubmissions.count];
    } else {
        NSLog(@"Attempted to insert nil into form submissions queue.");
    }
}

- (NSDictionary *)dequeueFormSubmissionForIdentifier:(NSUInteger)identifier {
    NSUInteger index = [self indexOfObjectWithIdentifier:identifier inArray:self.queuedFormSubmissions];
    if (index == NSNotFound) {
        return nil;
    }
    NSDictionary *form = [self.queuedFormSubmissions objectAtIndex:index];
    [self.queuedFormSubmissions removeObjectAtIndex:index];
    return form;
}

- (NSDictionary *)dequeueVideoForIdentifier:(NSUInteger)identifier {
    NSUInteger index = [self indexOfObjectWithIdentifier:identifier inArray:self.queuedVideoSubmissions];
    if (index == NSNotFound) {
        return nil;
    }
    NSDictionary *video = [self.queuedVideoSubmissions objectAtIndex:index];
    [self.queuedVideoSubmissions removeObjectAtIndex:index];
    return video;
}

- (BOOL)startProcessingQueue {
    // If there's nothing already processing
    if (!self.currentFormSubmission && !self.currentVideoSubmission) {
        // Search to find the lowest index from the queued videos
        // Always start by uploading a video
        NSArray *identifiers = [self.queuedVideoSubmissions valueForKey:kIdentifierKey];
        
        if (identifiers.count > 0) {
            NSNumber *lowestIdentifier = identifiers[0];
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
            NSArray *identifiers = [self.queuedFormSubmissions valueForKey:kIdentifierKey];
            
            if (identifiers.count > 0) {
                NSNumber *lowestIdentifier = identifiers[0];
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

// A unique key representing the video data / form data pairing
- (NSUInteger)generateUniqueIdentifier {
    return self.currentUniqueIdentifier++;
}

- (NSUInteger)indexOfObjectWithIdentifier:(NSUInteger)identifier inArray:(NSArray *)array {
    NSArray *identifiersArray = [array valueForKey:kIdentifierKey];
    return [identifiersArray indexOfObject:@(identifier)];
}

- (void)queueVideoAtURL:(NSURL *)videoURL identifier:(NSUInteger)identifier {
    if (videoURL) {
        [self.queuedVideoSubmissions addObject:@{kIdentifierKey : @(identifier), kDataKey : videoURL}];
    }
    NSLog(@"Attempted to insert nil into videos submissions queue.");
}

- (void)queueVideoResponseURL:(NSString *)videoURL forIdentifier:(NSUInteger)identifier {
    if (videoURL && ![videoURL isEqualToString:@""]) {
        NSUInteger index = [self indexOfObjectWithIdentifier:identifier inArray:self.queuedVideoSubmissions];
        
        NSMutableDictionary *existingDictionary = index != NSNotFound ? [NSMutableDictionary dictionaryWithDictionary:[self.queuedFormSubmissions objectAtIndex:index]] : [NSMutableDictionary dictionaryWithObject:@(identifier) forKey:kIdentifierKey];
        
        [existingDictionary setObject:videoURL forKey:kVideoURLKey];
        [self.queuedFormSubmissions setObject:existingDictionary atIndexedSubscript:index != NSNotFound ? index : self.queuedFormSubmissions.count];
    } else {
        NSLog(@"Attempted to insert nil or empty video URL into form submissions queue.");
    }
}

- (void)submitVideoWithIdentifier:(NSUInteger)identifier completion:(void (^)(NSString *videoURL))completion {
    NSDictionary *videoSubmission = [self dequeueVideoForIdentifier:identifier];
    NSURL *fileURL = videoSubmission[kDataKey];
    
    if (fileURL) {
        self.currentVideoSubmission = videoSubmission;
        
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
    // Check here for nil PLEASE
    if (input && videoURL) {
        self.currentFormSubmission = formSubmissionDictionary;
        
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
            [self.queuedFormSubmissions addObject:self.currentFormSubmission];
            
            // reset the current form submission
            self.currentFormSubmission = nil;
            
            // return no
            completion(NO);
        }];
    } else {
        NSLog(@"Inputted form dictionary was nil. Not submitting.");
        // requeue the failed submission
        [self queueFormSubmissionWithDictionary:input identifier:identifier];
        [self queueVideoResponseURL:videoURL forIdentifier:identifier];
        
        // return no
        completion(NO);
    }
}


@end
