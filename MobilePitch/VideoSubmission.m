//
//  VideoSubmission.m
//  MobilePitch
//
//  Created by Nathan Wallace on 11/6/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "VideoSubmission.h"
#import "FormSubmission.h"

#define kIdentifierKey @"kIdentifierKey"
#define kFileURLKey @"kFileURLKey"
#define kFormSubmissionKey @"kFormSubmissionKey"

@implementation VideoSubmission

- (instancetype)init {
    return [self initWithIdentifier:0 forFileURL:[NSURL URLWithString:@""]];
}

- (instancetype)initWithIdentifier:(NSUInteger)identifer forFileURL:(NSURL *)url {
    if (self = [super init]) {
        _identifier = identifer;
        _fileName = [url lastPathComponent];
        //_formSubmission = [[FormSubmission alloc] initWithIdentifier:identifer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSNumber *identifierNumber = [aDecoder decodeObjectForKey:kIdentifierKey];
        _identifier = identifierNumber ? identifierNumber.unsignedIntegerValue : 0;
        
        NSString *fileURL = [aDecoder decodeObjectForKey:kFileURLKey];
        _fileName = fileURL ? fileURL : @"";
        
        //FormSubmission *submission = [aDecoder decodeObjectForKey:kFormSubmissionKey];
        //_formSubmission = submission ? submission : [[FormSubmission alloc] initWithIdentifier:_identifier];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.identifier) forKey:kIdentifierKey];
    [aCoder encodeObject:self.fileName forKey:kFileURLKey];
    //[aCoder encodeObject:self.formSubmission forKey:kFormSubmissionKey];
}

@end
