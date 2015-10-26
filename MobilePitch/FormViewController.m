//
//  FormViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/25/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "FormViewController.h"
#import "FormTableViewCell.h"

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

@property (strong, nonatomic) NSArray *formItems;

@end

static NSString *cellIdentifier = @"kCellIdentifier";

@implementation FormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Initialize form items
    [self createFormItems];
    
    // Set nav bar title
    self.navigationItem.title = @"Pitch Submission";
    
    // Set right bar button item
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
    
    // Set tint color
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    
    // Add background graphics
    self.view.backgroundColor = [UIColor colorWithRed:0.286 green:0.561 blue:0.729 alpha:1];
    
    // Register table view cell
    [self.tableView registerClass:[FormTableViewCell class] forCellReuseIdentifier:cellIdentifier];
    
    // Set separator style
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.formItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FormTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    [cell setTitle:@"First Name" required:YES];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 83;
}

#pragma mark Actions

- (void)cancelButtonTapped:(id)sender {
    
}

#pragma mark Helpers

- (void)createFormItems {
    self.formItems = @[
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
