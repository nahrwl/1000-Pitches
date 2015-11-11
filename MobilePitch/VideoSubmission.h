//
//  VideoSubmission.h
//  MobilePitch
//
//  Created by Nathan Wallace on 11/6/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoSubmission : NSObject <NSCoding>

@property (nonatomic) NSUInteger identifier;
@property (strong, nonatomic) NSURL *fileURL;

- (instancetype)initWithIdentifier:(NSUInteger)identifer forFileURL:(NSURL *)url;

@end
