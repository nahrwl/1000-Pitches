//
//  FormViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/25/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "FormViewController.h"
#import "FormRowView.h"

// Form item constants
#define kFormItemTitleKey @"kFormItemTitleKey"
#define kFormItemRequiredKey @"kFormItemRequiredKey"
#define kFormItemInputTypeKey @"kFormItemInputTypeKey"

typedef NS_ENUM(NSInteger, FormCellType) {
    FormCellTypeTextField,
    FormCellTypePicker,
    FormCellTypeShortAnswer
};

@interface FormViewController ()

// Views
@property (weak, nonatomic) UIScrollView *scrollView;
@property (weak, nonatomic) UIStackView *stackView;

@end

static NSString *cellIdentifier = @"kCellIdentifier";

@implementation FormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Set nav bar title
    self.navigationItem.title = @"Pitch Submission";
    
    // Set right bar button item
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
    
    // Set tint color
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    
    // Add background graphics
    self.view.backgroundColor = [UIColor colorWithRed:0.286 green:0.561 blue:0.729 alpha:1];
    
    // Populate the Stack View
    NSArray *formItems = [FormViewController createFormItems];
    
    for (int i = 0; i < formItems.count; i++) {
        FormRowView *rowView = [[FormRowView alloc] init];
        [rowView setTitle:formItems[i][kFormItemTitleKey] required:[(NSNumber *)formItems[i][kFormItemRequiredKey] boolValue]];
        [self.stackView addArrangedSubview:rowView];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Make nav bar visible
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.stackView.frame.size.height);
}

- (void)loadView {
    UIView *view = [[UIView alloc] init];
    self.view = view;
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:scrollView];
    self.scrollView = scrollView;
    
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(scrollView)]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(scrollView)]];
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    [scrollView addSubview:stackView];
    self.stackView = stackView;
    
    [stackView.leftAnchor constraintEqualToAnchor:view.leftAnchor].active = YES;
    [stackView.rightAnchor constraintEqualToAnchor:view.rightAnchor].active = YES;
    
    [scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[stackView]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(stackView)]];
    
    // Configure the stack view
    self.stackView.alignment = UIStackViewAlignmentFill;
    self.stackView.distribution = UIStackViewDistributionFill;
    
    NSLog(@"stack view width: %f",self.stackView.frame.size.width);
}

#pragma mark Actions

- (void)cancelButtonTapped:(id)sender {
    NSLog(@"stack view width: %f",self.stackView.frame.size.width);
}

#pragma mark Helpers

+ (NSArray *)createFormItems {
    return @[
                       @{kFormItemTitleKey : @"First Name",
                         kFormItemRequiredKey : @(YES),
                         kFormItemInputTypeKey : @(FormCellTypeTextField)},
                       
                       @{kFormItemTitleKey : @"Last Name",
                         kFormItemRequiredKey : @(YES),
                         kFormItemInputTypeKey : @(FormCellTypeTextField)},
                       
                       @{kFormItemTitleKey : @"USC Email",
                         kFormItemRequiredKey : @(YES),
                         kFormItemInputTypeKey : @(FormCellTypeTextField)},
                       
                       @{kFormItemTitleKey : @"Student Organization Name",
                         kFormItemRequiredKey : @(NO),
                         kFormItemInputTypeKey : @(FormCellTypeTextField)},
                       
                       @{kFormItemTitleKey : @"College",
                         kFormItemRequiredKey : @(YES),
                         kFormItemInputTypeKey : @(FormCellTypePicker)},
                       
                       @{kFormItemTitleKey : @"Graduation Year",
                         kFormItemRequiredKey : @(YES),
                         kFormItemInputTypeKey : @(FormCellTypePicker)},
                       
                       @{kFormItemTitleKey : @"Pitch Title",
                         kFormItemRequiredKey : @(YES),
                         kFormItemInputTypeKey : @(FormCellTypeTextField)},
                       
                       @{kFormItemTitleKey : @"Pitch Category",
                         kFormItemRequiredKey : @(YES),
                         kFormItemInputTypeKey : @(FormCellTypePicker)},
                       
                       @{kFormItemTitleKey : @"Short Pitch Description",
                         kFormItemRequiredKey : @(YES),
                         kFormItemInputTypeKey : @(FormCellTypeShortAnswer)}
                       ];
}



@end
