//
//  FormRowListView.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/17/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import "FormRowView.h"

@class SmarterTextField;

@interface FormRowListView : FormRowView

@property (strong, nonatomic, readonly) NSArray<SmarterTextField *> *textFields;

- (instancetype)initWithRows:(NSUInteger)rows;

@end
