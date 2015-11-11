//
//  VideoSubmission.m
//  MobilePitch
//
//  Created by Nathan Wallace on 11/6/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "VideoSubmission.h"

#define kIdentifierKey @"kIdentifierKey"
#define kFileURLKey @"kFileURLKey"

@implementation VideoSubmission

- (instancetype)init {
    return [self initWithIdentifier:0 forFileURL:[NSURL URLWithString:@""]];
}

- (instancetype)initWithIdentifier:(NSUInteger)identifer forFileURL:(NSURL *)url {
    if (self = [super init]) {
        _identifier = identifer;
        _fileURL = url;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSNumber *identifierNumber = [aDecoder decodeObjectForKey:kIdentifierKey];
        _identifier = identifierNumber ? identifierNumber.unsignedIntegerValue : 0;
        
        NSURL *fileURL = [aDecoder decodeObjectForKey:kFileURLKey];
        _fileURL = fileURL ? fileURL : [NSURL URLWithString:@""];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.identifier) forKey:kIdentifierKey];
    [aCoder encodeObject:self.fileURL forKey:kFileURLKey];
}

@end
