//
//  FormViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/25/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//

#import "FormViewController.h"
#import "FormRowTextFieldView.h"
#import "FormRowTextViewView.h"
#import "FormRowListView.h"
#import "NicerLookingPickerView.h"
#import "SmarterTextField.h"
#import "ShadowView.h"
#import "SplashView.h"
#import "SubmissionManager.h"
#import "FinishedViewController.h"

// Form item constants
#define kFormItemTitleKey @"kFormItemTitleKey"
#define kFormItemPlaceholderKey @"kFormItemPlaceholderKey"
#define kFormItemRequiredKey @"kFormItemRequiredKey"
#define kFormItemInputTypeKey @"kFormItemInputTypeKey"
#define kFormItemSubmissionKeyKey @"kFormItemSubmissionKeyKey"
#define kFormItemOptionsKey @"kFormItemOptionsKey"

#define kScrollViewTopInset 208

typedef NS_ENUM(NSInteger, FormCellType) {
    FormCellTypeTextField,
    FormCellTypePicker,
    FormCellTypeShortAnswer
};

@interface FormViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UITextViewDelegate>

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
    
    // Set tint color
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    
    // Remove nav bar transparency
    self.navigationController.navigationBar.translucent = NO;
    
    // Change the bar tint color to match the form background
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.953 green:0.953 blue:0.953 alpha:1];
    
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
        
        if ([(NSNumber *)row[kFormItemInputTypeKey] integerValue] == FormCellTypeShortAnswer)
        {
            FormRowTextViewView *rowView = [[FormRowTextViewView alloc] init];
            [rowView setTitle:row[kFormItemTitleKey] required:[(NSNumber *)row[kFormItemRequiredKey] boolValue]];
            [self.stackView insertArrangedSubview:rowView atIndex:self.stackView.arrangedSubviews.count - 1];
            
            // Configure the row
            rowView.textView.delegate = self;
            
            // Store the row index in the text view's tag... don't judge me
            rowView.textView.tag = 1000 + i;
        }
        else if ([(NSNumber *)row[kFormItemInputTypeKey] integerValue] == FormCellTypePicker)
        {
            NSArray *listItems = self.formItems[i][kFormItemOptionsKey];
            FormRowListView *rowView = [[FormRowListView alloc] initWithRows:listItems.count];
            for (int j = 0; j < rowView.textFields.count; j++)
            {
                rowView.textFields[j].text = listItems[j];
            }
            
            [rowView setTitle:row[kFormItemTitleKey] required:[(NSNumber *)row[kFormItemRequiredKey] boolValue]];
            [self.stackView insertArrangedSubview:rowView atIndex:self.stackView.arrangedSubviews.count - 1];
            
            // Store the row index in the text field's tag... don't judge me
            rowView.textFields[0].tag = 1000 + i;
        }
        else
        {
            FormRowTextFieldView *rowView = [[FormRowTextFieldView alloc] init];
            [rowView setTitle:row[kFormItemTitleKey] required:[(NSNumber *)row[kFormItemRequiredKey] boolValue]];
            [self.stackView insertArrangedSubview:rowView atIndex:self.stackView.arrangedSubviews.count - 1];
            
            // Configure the row
            
            // Set the row delegate to self to recieve updates about editing
            rowView.textField.delegate = self;
            
            // Store the row index in the text field's tag... don't judge me
            rowView.textField.tag = 1000 + i;
            
            // Disable autocorrect
            rowView.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            
            // If the row is the email row, give it the right kind of keyboard
            if ([row[kFormItemSubmissionKeyKey] isEqualToString:@"email"]) {
                [rowView.textField setKeyboardType:UIKeyboardTypeEmailAddress];
                rowView.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            }
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDisplay:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillUndisplay) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidDisplay:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidUndisplay) name:UIKeyboardDidHideNotification object:nil];
}

- (void)removeObservers {
    
}

- (void)keyboardWillDisplay:(NSNotification*)aNotification {
    // Update the nav bar buttons
    
    // Change the right bar button item to be a Done button
    if (!(self.navigationItem.rightBarButtonItem.action == @selector(dismissInputView))) {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    }
}

- (void)keyboardWillUndisplay { // is undisplay a word?
    // Update the nav bar buttons
    
    // Set right bar button item to be the Clear button
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    
    // Show the back button
    [self.navigationItem setHidesBackButton:NO animated:YES];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(kScrollViewTopInset, 0, 0, 0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardDidDisplay:(NSNotification*)aNotification {
    // Update the nav bar buttons
    
    if (!(self.navigationItem.rightBarButtonItem.action == @selector(dismissInputView))) {
        // Change the right bar button item to be a Done button
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissInputView)] animated:YES];
    }
    
    // Hide the back button
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(kScrollViewTopInset, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    // If this is the last item in the form, scroll so the submit button is visible
    if (self.selectedRow == self.formItems.count - 1) {
        [self.scrollView scrollRectToVisible:CGRectMake(self.scrollView.contentSize.width - 1,self.scrollView.contentSize.height - 1, 1, 1) animated:YES];
    } else {
        UIView *activeField = [self.view viewWithTag:self.selectedRow + 1000];
        if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
            // I don't think this ever gets called
            // Some magic being is scrolling my views for me
            // Or I'm just crazy...
            //[self.scrollView scrollRectToVisible:activeField.frame animated:YES];
        }
    }
}

- (void)keyboardDidUndisplay { // is undisplay a word?
    // Update the nav bar buttons
    
    // Set right bar button item to be nothing
    [self.navigationItem setRightBarButtonItem:nil];
    // Show the back button
    //[self.navigationItem setHidesBackButton:NO animated:YES];
}

#pragma mark Text View Delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // Configure the current editing environment
    
    // The text view's row is stored in its tag.
    // Note this only works because the form is static. Please do not attempt with dynamic table view.
    self.selectedRow = textView.tag - 1000;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    // Trim the textField's contents
    textView.text = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Validate the contents
    NSUInteger index = textView.tag - 1000;
    NSDictionary *formRow = self.formItems[index];
    if ([(NSNumber *)formRow[kFormItemRequiredKey] boolValue] && [textView.text isEqualToString:@""]) {
        // Error!
        [self setError:YES forView:textView];
    } else {
        [self setError:NO forView:textView];
    }
}

#pragma mark Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // Configure the current editing environment
    
    // The text field's row is stored in its tag.
    // Note this only works because the form is static. Please do not attempt with dynamic table view.
    self.selectedRow = textField.tag - 1000;
    
    // Tell the picker view to update
    [self.pickerView reloadAllComponents];
    
    // Find the index of the textField's contents in the array
    
    // Default index is 0
    int index = 0;
    // the if is to prevent a crash if the index does not exist
    // If there are no options, this will simply send a message to nil!
    if ([self.formItems[self.selectedRow][kFormItemOptionsKey] containsObject:textField.text]) {
        // Xcode, I do not care that this is losing precision. This does not need to be a long, trust me.
        index = (int)[self.formItems[self.selectedRow][kFormItemOptionsKey] indexOfObject:textField.text];
    }
    
    // Now select the first row of the picker view to reset it
    [self.pickerView selectRow:index inComponent:0 animated:NO];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // Trim the textField's contents
    textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Validate the contents
    NSUInteger index = textField.tag - 1000;
    NSDictionary *formRow = self.formItems[index];
    if ([(NSNumber *)formRow[kFormItemRequiredKey] boolValue] && [textField.text isEqualToString:@""]) {
        // Error!
        [self setError:YES forView:textField];
    } else if ([formRow[kFormItemSubmissionKeyKey] isEqualToString:@"email"] && ![textField.text hasSuffix:@"@usc.edu"]) {
        // the if expression is just a jank way to check for the email field
        [self setError:YES forView:textField];
    } else {
        [self setError:NO forView:textField];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Disable editing the text field if it uses the picker view for input
    
    // Is this efficient? Is there a better way?
    if ([textField.inputView isEqual:self.pickerView]) {
        return NO;
    }
    
    // Insert @usc.edu when the @ key is pressed for the email field
    NSUInteger index = textField.tag - 1000;
    NSDictionary *formRow = self.formItems[index];
    if ([formRow[kFormItemSubmissionKeyKey] isEqualToString:@"email"] && [string isEqualToString:@"@"]) {
        if ([textField.text containsString:@"@"]) {
            return NO;
        } else {
            textField.text = [textField.text stringByAppendingString:@"@usc.edu"];
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // Find the next text field to edit
    UIView *nextInputView = [self.view viewWithTag:textField.tag + 1];
    [nextInputView becomeFirstResponder];
    
    // Not sure what default behavior is here, but we don't want it.
    return NO;
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
    UITextField *textField = [self.view viewWithTag:self.selectedRow + 1000];
    textField.text = self.formItems[self.selectedRow][kFormItemOptionsKey][row];
}

#pragma mark Actions

- (void)submitButtonTapped:(id)sender {
    NSLog(@"Submit button tapped!");
    
    // Extract all the values from the form views and put it in the dictionary
    
    NSInteger errorIndex = -1;
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    for (int i = 0; i < self.formItems.count; i++) {
        NSDictionary *formItem = self.formItems[i];
        FormCellType cellType = [(NSNumber *)formItem[kFormItemInputTypeKey] integerValue];
        NSString *rowValue = @"";
        switch (cellType) {
            case FormCellTypePicker:
            case FormCellTypeTextField: {
                UITextField *textField = (UITextField *)[self.view viewWithTag:i + 1000];
                rowValue = textField.text;
                break;
            }
            case FormCellTypeShortAnswer: {
                UITextView *textView = (UITextView *)[self.view viewWithTag:i + 1000];
                rowValue = textView.text;
                break;
            }
        }
        
        // Trim the string
        rowValue = [rowValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([(NSNumber *)formItem[kFormItemRequiredKey] boolValue] && [rowValue isEqualToString:@""]) {
            // If the item is required, check that the string is not empty
            
            // errorIndex should be the first field with a problem
            if (errorIndex == -1) {
                errorIndex = i;
            }
            [self setError:YES forView:[self.view viewWithTag:i + 1000]];
        } else {
            [parameters setObject:rowValue forKey:formItem[kFormItemSubmissionKeyKey]];
        }
    }
    
    if (errorIndex != -1) {
        // Something went wrong - form not filled out properly
        NSLog(@"Form not filled out fully!");
        
        // Set the highest field to become the first responder
        [[self.view viewWithTag:errorIndex + 1000] becomeFirstResponder];
    } else {
        [[SubmissionManager sharedManager] submitCurrentSubmissionWithFormData:[parameters copy]];
        
        [self.navigationController pushViewController:[[FinishedViewController alloc] init] animated:YES];
    }
}

- (void)dismissInputView {
    [self.view endEditing:YES];
}

- (void)selectNextRow {
    
}

- (void)selectPreviousRow {
    
}

#pragma mark Helpers

- (void)setError:(BOOL)error forView:(UIView *)view {
    if (error) {
        view.layer.borderColor = [UIColor colorWithRed:0.796 green:0 blue:0 alpha:1].CGColor;
    } else {
        view.layer.borderColor = [UIColor colorWithRed:0.886 green:0.886 blue:0.886 alpha:1].CGColor;
    }
}

+ (NSArray *)createFormItems {
    return @[
             @{kFormItemTitleKey : @"First Name",
               kFormItemPlaceholderKey : @"Tommy",
               kFormItemRequiredKey : @(YES),
               kFormItemSubmissionKeyKey : @"first_name",
               kFormItemInputTypeKey : @(FormCellTypeTextField)},
             
             @{kFormItemTitleKey : @"Last Name",
               kFormItemPlaceholderKey : @"Trojan",
               kFormItemRequiredKey : @(YES),
               kFormItemSubmissionKeyKey : @"last_name",
               kFormItemInputTypeKey : @(FormCellTypeTextField)},
             
             @{kFormItemTitleKey : @"USC Email",
               kFormItemPlaceholderKey : @"ttrojan@usc.edu",
               kFormItemRequiredKey : @(YES),
               kFormItemSubmissionKeyKey : @"email",
               kFormItemInputTypeKey : @(FormCellTypeTextField)},
             
             @{kFormItemTitleKey : @"Student Organization Name",
               kFormItemRequiredKey : @(NO),
               kFormItemSubmissionKeyKey : @"student_org",
               kFormItemInputTypeKey : @(FormCellTypeTextField)},
             
             @{kFormItemTitleKey : @"College",
               kFormItemRequiredKey : @(YES),
               kFormItemSubmissionKeyKey : @"college",
               kFormItemInputTypeKey : @(FormCellTypePicker),
               kFormItemOptionsKey : @[@"Letters, Arts and Sciences",
                                       @"Accounting",
                                       @"Architecture",
                                       @"Business",
                                       @"Arts, Technology, Business",
                                       @"Cinematic Arts",
                                       @"Communication",
                                       @"Dance",
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
               kFormItemSubmissionKeyKey : @"grad_year",
               kFormItemInputTypeKey : @(FormCellTypePicker),
               kFormItemOptionsKey : @[@"2016",
                                       @"2017",
                                       @"2018",
                                       @"2019",
                                       @"2020",
                                       @"2021",
                                       @"2022"]},
             
             @{kFormItemTitleKey : @"Pitch Title",
               kFormItemRequiredKey : @(YES),
               kFormItemSubmissionKeyKey : @"pitch_title",
               kFormItemInputTypeKey : @(FormCellTypeTextField)},
             
             @{kFormItemTitleKey : @"Pitch Category",
               kFormItemRequiredKey : @(YES),
               kFormItemSubmissionKeyKey : @"pitch_category",
               kFormItemInputTypeKey : @(FormCellTypePicker),
               kFormItemOptionsKey : @[@"Art & Interactive Media",
                                       @"Community Impact",
                                       @"Education",
                                       @"Enterprise & Commerce",
                                       @"Environment",
                                       @"Health & Biotech",
                                       @"Household & Everyday Products",
                                       @"Media & Entertainment",
                                       @"Services",
                                       @"Small Business",
                                       @"Social & Lifestyle",
                                       @"USC Community"]},
             
             @{kFormItemTitleKey : @"Short Pitch Description",
               kFormItemRequiredKey : @(YES),
               kFormItemSubmissionKeyKey : @"pitch_short_description",
               kFormItemInputTypeKey : @(FormCellTypeShortAnswer)}
             ];
}

#pragma mark Load View

- (void)loadView {
    SplashView *view = [[SplashView alloc] init];
    self.view = view;
    
    // Add background graphics
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"form-logo"]];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:logo];
    // Autolayout
    NSArray *vLogoConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-30-[logo]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(logo)];
    [view addConstraints:vLogoConstraints];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:logo attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    // Scroll view
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:scrollView];
    self.scrollView = scrollView;
    // Appearance
    // Set inset so the 1000 pitches logo is visible
    scrollView.contentInset = UIEdgeInsetsMake(kScrollViewTopInset, 0, 0, 0);
    
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
    
    // Add top top spacer to stack view
    ShadowView *shadowView = [[ShadowView alloc] init];
    shadowView.translatesAutoresizingMaskIntoConstraints = NO;
    [stackView addArrangedSubview:shadowView];
    // Appearance
    
    [shadowView addConstraint:[NSLayoutConstraint constraintWithItem:shadowView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:10]];
    
    // Add top spacer to stack view
    UIView *spacerView = [[UIView alloc] init];
    spacerView.translatesAutoresizingMaskIntoConstraints = NO;
    [stackView addArrangedSubview:spacerView];
    // Appearance
    spacerView.backgroundColor = [UIColor colorWithRed:0.953 green:0.953 blue:0.953 alpha:1];
    [spacerView addConstraint:[NSLayoutConstraint constraintWithItem:spacerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:34]];
    
    // Configure drop shadow
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:spacerView.bounds];
    spacerView.layer.masksToBounds = NO;
    spacerView.layer.shadowColor = [UIColor blackColor].CGColor;
    spacerView.layer.shadowOffset = CGSizeMake(0.0f, -4.0f);
    spacerView.layer.shadowOpacity = 0.8f;
    spacerView.layer.shadowPath = shadowPath.CGPath;
    
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
