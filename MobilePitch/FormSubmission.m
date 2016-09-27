//
//  FormSubmission.m
//  MobilePitch
//
//  Created by Nathan Wallace on 11/15/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "FormSubmission.h"

#define kIdentifierKey @"kIdentifierKey"
#define kFormDataKey @"kFormDataKey"
#define kServerURLKey @"kServerURLKey"

static NSString *baseURL = @"http://1kp-api-dev.us-west-1.elasticbeanstalk.com";

@interface FormSubmission ()

@property (nonatomic) BOOL uploading;

@end

@implementation FormSubmission

- (instancetype)initWithIdentifier:(NSUInteger)identifier {
    if (self = [super init]) {
        _identifier = identifier;
        _uploading = NO;
    }
    return self;
}

- (instancetype)init {
    return [self initWithIdentifier:0];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSNumber *identifierNumber = [aDecoder decodeObjectForKey:kIdentifierKey];
        _identifier = identifierNumber ? identifierNumber.unsignedIntegerValue : 0;
        
        NSDictionary *formData = [aDecoder decodeObjectForKey:kFormDataKey];
        _formData = formData;
        
        NSString *url = [aDecoder decodeObjectForKey:kServerURLKey];
        _serverURL = url;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.identifier) forKey:kIdentifierKey];
    [aCoder encodeObject:self.formData forKey:kFormDataKey];
    [aCoder encodeObject:self.serverURL forKey:kServerURLKey];
}

- (BOOL)isComplete {
    return self.formData && self.serverURL;
}

#pragma mark Submission

- (void)submitWithCompletion:(void (^)(BOOL))completion {
    if ([self isComplete] && !self.uploading) {
        self.uploading = YES;
        
        NSDictionary *input = self.formData;
        NSString *videoURL = self.serverURL;
        
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
            
            self.uploading = NO;
            
            // return yes
            completion(YES);
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            
            //here is place for code executed in error case
            
            NSLog(@"Error: %@", [error localizedDescription]);
            
            self.uploading = NO;
            
            // return no
            completion(NO);
        }];
    } else if (self.uploading) {
        NSLog(@"FormSubmission with id %lu is already uploading.",self.identifier);
    } else {
        NSLog(@"FormSubmission with id %lu is not complete. Not submitting.",(unsigned long)self.identifier);
        
        // return no
        completion(NO);
    }
}

@end
