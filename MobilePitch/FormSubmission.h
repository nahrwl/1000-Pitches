//
//  FormSubmission.h
//  MobilePitch
//
//  Created by Nathan Wallace on 11/15/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FormSubmission : NSObject <NSCoding>

@property (nonatomic) NSUInteger identifier;
@property (strong, nonatomic) NSDictionary *formData;
@property (strong, nonatomic) NSString *serverURL;

- (instancetype)initWithIdentifier:(NSUInteger)identifier;

- (BOOL)isComplete;

- (void)submitWithCompletion:(void (^)(BOOL success))completion;

@end
