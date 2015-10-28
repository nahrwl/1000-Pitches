//
//  FormViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/25/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "FormViewController.h"
#import "FormRowView.h"
#import "NicerLookingPickerView.h"
#import "SmarterTextField.h"

// Form item constants
#define kFormItemTitleKey @"kFormItemTitleKey"
#define kFormItemPlaceholderKey @"kFormItemPlaceholderKey"
#define kFormItemRequiredKey @"kFormItemRequiredKey"
#define kFormItemInputTypeKey @"kFormItemInputTypeKey"
#define kFormItemOptionsKey @"kFormItemOptionsKey"

typedef NS_ENUM(NSInteger, FormCellType) {
    FormCellTypeTextField,
    FormCellTypePicker,
    FormCellTypeShortAnswer
};

@interface FormViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>

// Views
@property (weak, nonatomic) UIScrollView *scrollView;
@property (weak, nonatomic) UIStackView *stackView;
@property (weak, nonatomic) UIPickerView *pickerView;

// Editing
@property (strong, nonatomic) NSArray *formItems;
@property (nonatomic) NSUInteger selectedRow;

@end

static NSString *cellIdentifier = @"kCellIdentifier";

@implementation FormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Register for notifications and add observers
    [self addObservers];
    
    // Set nav bar title
    self.navigationItem.title = @"Pitch Submission";
    
    // Set right bar button item
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
    
    // Set tint color
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    
    // Create the form items. Technically could be loaded in from a plist or something.
    NSArray *formItems = [FormViewController createFormItems];
    self.formItems = formItems;
    
    // Create the picker view
    NicerLookingPickerView *pickerView = [[NicerLookingPickerView alloc] init];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    self.pickerView = pickerView;
    
    // Create the toolbar
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.tintColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    toolbar.barTintColor = [UIColor whiteColor];
    toolbar.translucent = NO;
    UIBarButtonItem *previous = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(selectPreviousRow)];
    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(selectNextRow)];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissInputView)];
    [toolbar setItems:@[previous, next, spacer, doneButton]];
    
    // Populate the Stack View
    for (int i = 0; i < formItems.count; i++) {
        NSDictionary *row = formItems[i];
        FormRowView *rowView = [[FormRowView alloc] init];
        [rowView setTitle:row[kFormItemTitleKey] required:[(NSNumber *)row[kFormItemRequiredKey] boolValue]];
        [self.stackView insertArrangedSubview:rowView atIndex:self.stackView.arrangedSubviews.count - 1];
        
        // Configure the row
        
        // Set the row delegate to self to recieve updates about editing
        rowView.textField.delegate = self;
        
        // Store the row index in the text field's tag... don't judge me
        rowView.textField.tag = i;
        
        // Configure the toolbar
        //rowView.textField.inputAccessoryView = toolbar;
        
        // If the row requires the picker view, configure that now
        if ([(NSNumber *)row[kFormItemInputTypeKey] integerValue] == FormCellTypePicker) {
            // Add the picker view as the text field's input view
            // This replaces the keyboard
            rowView.textField.inputView = pickerView;
            
            // Disable the text field cursor so we don't get the blue input indicator thingy
            rowView.textField.cursorEnabled = NO;
            
            // Set an initial value for the field
            rowView.textField.text = row[kFormItemOptionsKey][0];
        }
        
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

#pragma mark KVO and Notifications

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDisplay) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillUndisplay) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidDisplay) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidUndisplay) name:UIKeyboardDidHideNotification object:nil];
}

- (void)removeObservers {
    
}

- (void)keyboardWillDisplay {
    // Update the nav bar buttons
    
    // Change the right bar button item to be a Done button
    if (!(self.navigationItem.rightBarButtonItem.action == @selector(dismissInputView))) {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    }
    
    // Hide the back button
    [self.navigationItem setHidesBackButton:YES animated:YES];
}

- (void)keyboardWillUndisplay { // is undisplay a word?
    // Update the nav bar buttons
    
    // Set right bar button item to be the Clear button
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    
    // Show the back button
    [self.navigationItem setHidesBackButton:NO animated:YES];
}

- (void)keyboardDidDisplay {
    // Update the nav bar buttons
    
    if (!(self.navigationItem.rightBarButtonItem.action == @selector(dismissInputView))) {
        // Change the right bar button item to be a Done button
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissInputView)] animated:YES];
    }
}

- (void)keyboardDidUndisplay { // is undisplay a word?
    // Update the nav bar buttons
    
    // Set right bar button item to be the Clear button
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)] animated:YES];
    
    // Show the back button
    //[self.navigationItem setHidesBackButton:NO animated:YES];
}

#pragma mark Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // Configure the current editing environment
    
    // The text field's row is stored in its tag.
    // Note this only works because the form is static. Please do not attempt with dynamic table view.
    self.selectedRow = textField.tag;
    
    // Tell the picker view to update
    [self.pickerView reloadAllComponents];
    
    // Find the index of the textField's contents in the array
    
    // Default index is 0
    int index = 0;
    // the if is to prevent a crash if the index does not exist
    if ([self.formItems[self.selectedRow][kFormItemOptionsKey] containsObject:textField.text]) {
        // Xcode, I do not care that this is losing precision. This does not need to be a long, trust me.
        index = (int)[self.formItems[self.selectedRow][kFormItemOptionsKey] indexOfObject:textField.text];
    }
    
    // Now select the first row of the picker view to reset it
    [self.pickerView selectRow:index inComponent:0 animated:NO];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Disable editing the text field if it uses the picker view for input
    
    // Is this efficient? Is there a better way?
    if ([self.pickerView.inputView isEqual:self.pickerView]) {
        return NO;
    }
    return YES;
}

#pragma mark Picker View Data Source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSDictionary *row = self.formItems[self.selectedRow];
    if ([(NSNumber *)row[kFormItemInputTypeKey] integerValue] == FormCellTypePicker) {
        return [(NSArray *)row[kFormItemOptionsKey] count];
    }
    return 0;
}

#pragma mark Picker View Delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSDictionary *rowDictionary = self.formItems[self.selectedRow];
    if ([(NSNumber *)rowDictionary[kFormItemInputTypeKey] integerValue] == FormCellTypePicker) {
        return rowDictionary[kFormItemOptionsKey][row];
    }
    return nil;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    UITextField *textField = [self.view viewWithTag:self.selectedRow];
    textField.text = self.formItems[self.selectedRow][kFormItemOptionsKey][row];
}

#pragma mark Actions

- (void)submitButtonTapped:(id)sender {
    NSLog(@"Submit!");
}

- (void)cancelButtonTapped:(id)sender {
    NSLog(@"stack view width: %f",self.stackView.frame.size.width);
}

- (void)dismissInputView {
    [self.view endEditing:YES];
}

- (void)selectNextRow {
    
}

- (void)selectPreviousRow {
    
}

#pragma mark Helpers

+ (NSArray *)createFormItems {
    return @[
             @{kFormItemTitleKey : @"First Name",
               kFormItemPlaceholderKey : @"Tommy",
               kFormItemRequiredKey : @(YES),
               kFormItemInputTypeKey : @(FormCellTypeTextField)},
             
             @{kFormItemTitleKey : @"Last Name",
               kFormItemPlaceholderKey : @"Trojan",
               kFormItemRequiredKey : @(YES),
               kFormItemInputTypeKey : @(FormCellTypeTextField)},
             
             @{kFormItemTitleKey : @"USC Email",
               kFormItemPlaceholderKey : @"ttrojan@usc.edu",
               kFormItemRequiredKey : @(YES),
               kFormItemInputTypeKey : @(FormCellTypeTextField)},
             
             @{kFormItemTitleKey : @"Student Organization Name",
               kFormItemRequiredKey : @(NO),
               kFormItemInputTypeKey : @(FormCellTypeTextField)},
             
             @{kFormItemTitleKey : @"College",
               kFormItemRequiredKey : @(YES),
               kFormItemInputTypeKey : @(FormCellTypePicker),
               kFormItemOptionsKey : @[@"Letters, Arts and Sciences",
                                       @"Accounting",
                                       @"Architecture",
                                       @"Business",
                                       @"Arts, Technology, Business",
                                       @"Cinematic Arts",
                                       @"Communication",
                                       @"Dramatic Arts",
                                       @"Dentistry",
                                       @"Education",
                                       @"Engineering",
                                       @"Fine Arts",
                                       @"Gerontology",
                                       @"Law",
                                       @"Medicine",
                                       @"Music",
                                       @"Pharmacy",
                                       @"Policy, Planning, and Developement",
                                       @"Social Work"]},
             
             @{kFormItemTitleKey : @"Graduation Year",
               kFormItemRequiredKey : @(YES),
               kFormItemInputTypeKey : @(FormCellTypePicker),
               kFormItemOptionsKey : @[@"2019",
                                       @"2018",
                                       @"2017",
                                       @"2016"]},
             
             @{kFormItemTitleKey : @"Pitch Title",
               kFormItemRequiredKey : @(YES),
               kFormItemInputTypeKey : @(FormCellTypeTextField)},
             
             @{kFormItemTitleKey : @"Pitch Category",
               kFormItemRequiredKey : @(YES),
               kFormItemInputTypeKey : @(FormCellTypePicker),
               kFormItemOptionsKey : @[@"Consumer Products & Small Business",
                                       @"Education",
                                       @"Environment",
                                       @"Film",
                                       @"Health",
                                       @"Mobile Apps",
                                       @"Music",
                                       @"Research",
                                       @"Tech & Hardware",
                                       @"University Improvements",
                                       @"Web & Software"]},
             
             @{kFormItemTitleKey : @"Short Pitch Description",
               kFormItemRequiredKey : @(YES),
               kFormItemInputTypeKey : @(FormCellTypeShortAnswer)}
             ];
}

#pragma mark Load View

- (void)loadView {
    UIView *view = [[UIView alloc] init];
    self.view = view;
    
    // Add background pattern
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"grid-unit"]];
    
    // Add background graphics
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"form-logo"]];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:logo];
    // Autolayout
    NSArray *vLogoConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-115-[logo]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(logo)];
    [view addConstraints:vLogoConstraints];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:logo attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    // Scroll view
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:scrollView];
    self.scrollView = scrollView;
    // Appearance
    // Set inset so the 1000 pitches logo is visible
    scrollView.contentInset = UIEdgeInsetsMake(268, 0, 0, 0);
    
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
    
    // Add top spacer to stack view
    UIView *spacerView = [[UIView alloc] init];
    spacerView.translatesAutoresizingMaskIntoConstraints = NO;
    [stackView addArrangedSubview:spacerView];
    // Appearance
    spacerView.backgroundColor = [UIColor colorWithRed:0.953 green:0.953 blue:0.953 alpha:1];
    [spacerView addConstraint:[NSLayoutConstraint constraintWithItem:spacerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:34]];
    
    // Add bottom view
    UIView *bottomView = [[UIView alloc] init];
    bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    [stackView addArrangedSubview:bottomView];
    // Appearance
    bottomView.backgroundColor = [UIColor colorWithRed:0.953 green:0.953 blue:0.953 alpha:1];
    
    // Add button to bottom view
    // The button and its constraints will give intrinsic height to bottom view
    UIButton *bottomButton = [[UIButton alloc] init];
    bottomButton.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomView addSubview:bottomButton];
    [bottomButton addTarget:self action:@selector(submitButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    // Appearance
    bottomButton.backgroundColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    bottomButton.layer.cornerRadius = 8;
    // Button titleLabel formatting
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString: @"Submit"];
    [attributedString addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:20 weight:UIFontWeightSemibold]
                             range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:[UIColor whiteColor]
                             range:NSMakeRange(0, attributedString.length)];
    [bottomButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    // Button detail arrow
    UIImageView *arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"right arrow"]];
    arrow.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomButton addSubview:arrow];
    
    // AUTOLAYOUT
    NSDictionary *views = NSDictionaryOfVariableBindings(bottomButton);
    
    // Horizontal
    NSArray *horizontalButtonLayoutConstraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-33-[bottomButton]-33-|"
                                            options:NSLayoutFormatAlignAllCenterY
                                            metrics:nil
                                              views:views];
    [bottomView addConstraints:horizontalButtonLayoutConstraints];
    
    // Vertical
    NSArray *verticalLayoutConstraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-42-[bottomButton(48)]-32-|"
                                            options:NSLayoutFormatAlignAllCenterX
                                            metrics:nil
                                              views:views];
    [bottomView addConstraints:verticalLayoutConstraints];
    
    // Button detail
    NSArray *arrowHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[arrow]-13-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"arrow":arrow}];
    NSArray *arrowVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[arrow]-15-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"arrow":arrow}];
    [bottomButton addConstraints:arrowHConstraints];
    [bottomButton addConstraints:arrowVConstraints];
}




@end
