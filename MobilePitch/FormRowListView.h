//
//  FormRowListView.h
//  MobilePitch
//
//  Created by Nathan Wallace on 10/17/16.
//  Copyright © 2016 Spark Dev Team. All rights reserved.
//

#import "FormRowView.h"

@class SmarterTextField;
@class FormRowListView;


@protocol FormRowListViewDelegate <NSObject>

- (void)rowSelected:(NSInteger)index forView:(FormRowListView *)sender;

@end


@interface FormRowListView : FormRowView

@property (strong, nonatomic, readonly) NSArray<SmarterTextField *> *textFields;
@property (weak, nonatomic) id<FormRowListViewDelegate> delegate;

@property (nonatomic) NSInteger selectedRowIndex;

- (instancetype)initWithRows:(NSUInteger)rows;

@end
