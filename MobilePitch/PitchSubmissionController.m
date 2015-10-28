//
//  PitchSubmissionController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/28/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "PitchSubmissionController.h"
#import <AFNetworking/AFNetworking.h>

@implementation PitchSubmissionController

- (void)queueFormSubmissionWithDictionary:(NSDictionary *)formDictionary {
    NSString *baseURL = @"http://52.4.50.233";
    
    // Modify the inputted dictionary
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:formDictionary];
    
#warning Will get this value from the response during the video upload
    [parameters setObject:@"http://s3.amazonaws.com/spark-onekp/691f2de1-b75e-44dd-8af4-70749c16c1ea" forKey:@"video_url"];
    
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
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        //here is place for code executed in error case
        
        NSLog(@"Error: %@", [error localizedDescription]);
    }];
}

@end
