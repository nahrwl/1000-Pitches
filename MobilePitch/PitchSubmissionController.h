//
//  PitchSubmissionController.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/28/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import <Foundation/Foundation.h>

// Form Field Keys
#define kFormFieldFirstNameKey @"first_name"
#define kFormFieldLastNameKey @"last_name"
#define kFormFieldEmailKey @"email"
#define kFormFieldOrganizationKey @"student_org"
#define kFormFieldCollegeKey @"college"
#define kFormFieldGradYearKey @"grad_year"
#define kFormFieldPitchTitleKey @"pitch_title"
// kFormFieldPitchCategoryKey must be one of the following:
// Music, Film, Environment, Education, Tech & Hardware, Web & Software, Consumer Products & Small Business, Health, University Improvements, Mobile, Research, Video Games
#define kFormFieldPitchCategoryKey @"pitch_category";
#define kFormFieldPitchDescriptionKey @"pitch_short_description";

@protocol PitchSubmissionControllerDelegate <NSObject>

- (void)processingDidFail;
- (void)processingDidFinish;

@end

@interface PitchSubmissionController : NSObject <NSCoding>

@property (nonatomic, readonly) NSUInteger currentUniqueIdentifier;

@property (weak, nonatomic) id<PitchSubmissionControllerDelegate> delegate;

+ (PitchSubmissionController *)sharedPitchSubmissionController;
- (void)queueFormSubmissionWithDictionary:(NSDictionary *)formDictionary identifier:(NSUInteger)identifier;
- (NSUInteger)queueVideoAtURL:(NSURL *)videoURL;
- (NSDictionary *)dequeueVideoForIdentifier:(NSUInteger)identifier;
- (NSDictionary *)dequeueFormSubmissionForIdentifier:(NSUInteger)identifier;
- (BOOL)startProcessingQueue;

- (void)saveData;

@end
