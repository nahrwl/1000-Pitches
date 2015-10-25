//
//  CameraViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/24/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//
//  Much of this code was taken from Apple's AVCam demo.

@import AVFoundation;

#import "CameraViewController.h"
#import "AccessRequestViewController.h"
#import "AAPLPreviewView.h"

#define kRecordButtonAnimationDuration 0.2f

static void * SessionRunningContext = &SessionRunningContext;

typedef NS_ENUM(NSInteger, CamSetupResult) {
    CamSetupResultSuccess,
    CamSetupResultCameraNotAuthorized,
    CamSetupResultSessionConfigurationFailed
};

@interface CameraViewController ()

// Views
@property (nonatomic, weak) IBOutlet AAPLPreviewView *previewView;
@property (weak, nonatomic) UILabel *timerLabel;
@property (nonatomic, weak) UILabel *cameraUnavailableLabel;
@property (nonatomic, weak) UIButton *resumeButton;
@property (weak, nonatomic) UIButton *recordButton;
@property (weak, nonatomic) NSLayoutConstraint *recordButtonHeightConstraint;
@property (weak, nonatomic) NSLayoutConstraint *recordButtonWidthConstraint;

// Session management
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

// Utilities
@property (nonatomic) CamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

// Methods
- (void)recordButtonTapped:(UIButton *)sender;
- (void)toggleRecording;
- (void)backButtonTapped:(UIButton *)sender;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /*
    // Disable UI. The UI is enabled if and only if the session starts running.
    self.recordButton.enabled = NO;
    
    // Create the AVCaptureSession.
    self.session = [[AVCaptureSession alloc] init];
    
    // Setup the preview view.
    self.previewView.session = self.session;
    
    // Communicate with the session and other session objects on this queue.
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    
    self.setupResult = CamSetupResultSuccess;
    
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session setup until the access request has completed to avoid
            // asking the user for audio access if video access is denied.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend( self.sessionQueue );
            AccessRequestViewController *arvc = [[AccessRequestViewController alloc] init];
            arvc.modalPresentationStyle = UIModalPresentationOverFullScreen;
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                //code to be executed on the main queue after delay
                [self presentViewController:arvc animated:YES completion:nil];
            });
            self.setupResult = CamSetupResultCameraNotAuthorized;
            break;
        }
        default:
        {
            // The user has previously denied access.
            self.setupResult = CamSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    // Setup the capture session.
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
    // so that the main queue isn't blocked, which keeps the UI responsive.
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult != CamSetupResultSuccess ) {
            return;
        }
        
        self.backgroundRecordingID = UIBackgroundTaskInvalid;
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [CameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if ( ! videoDeviceInput ) {
            NSLog( @"Could not create video device input: %@", error );
        }
        
        [self.session beginConfiguration];
        
        if ( [self.session canAddInput:videoDeviceInput] ) {
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
            
            dispatch_async( dispatch_get_main_queue(), ^{
                // Why are we dispatching this to the main queue?
                // Because AVCaptureVideoPreviewLayer is the backing layer for AAPLPreviewView and UIView
                // can only be manipulated on the main thread.
                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                // on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                
                // Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
                // -[viewWillTransitionToSize:withTransitionCoordinator:].
                UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                    initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                }
                
                AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
                previewLayer.connection.videoOrientation = initialVideoOrientation;
            } );
        }
        else {
            NSLog( @"Could not add video device input to the session" );
            self.setupResult = CamSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if ( ! audioDeviceInput ) {
            NSLog( @"Could not create audio device input: %@", error );
        }
        
        if ( [self.session canAddInput:audioDeviceInput] ) {
            [self.session addInput:audioDeviceInput];
        }
        else {
            NSLog( @"Could not add audio device input to the session" );
        }
        
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ( [self.session canAddOutput:movieFileOutput] ) {
            [self.session addOutput:movieFileOutput];
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if ( connection.isVideoStabilizationSupported ) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            self.movieFileOutput = movieFileOutput;
        }
        else {
            NSLog( @"Could not add movie file output to the session" );
            self.setupResult = CamSetupResultSessionConfigurationFailed;
        }
        
        [self.session commitConfiguration];
    } );*/
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    /*
    dispatch_async( self.sessionQueue, ^{
        switch ( self.setupResult )
        {
            case CamSetupResultSuccess:
            {
                // Only setup observers and start the session running if setup succeeded.
                [self addObservers];
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case CamSetupResultCameraNotAuthorized:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            case CamSetupResultSessionConfigurationFailed:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
        }
    } );*/
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
}
/*
- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == CamSetupResultSuccess ) {
            [self.session stopRunning];
            [self removeObservers];
        }
    } );
    
    [super viewDidDisappear:animated];
}

#pragma mark KVO and Notifications

- (void)addObservers
{
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    // A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
    // see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
    // and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
    // interruption reasons.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.session removeObserver:self forKeyPath:@"running" context:SessionRunningContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == SessionRunningContext ) {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            self.recordButton.enabled = isSessionRunning;
        } );
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    // Automatically try to restart the session running if media services were reset and the last start running succeeded.
    // Otherwise, enable the user to try to resume the session running.
    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( self.sessionQueue, ^{
            if ( self.isSessionRunning ) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            }
            else {
                dispatch_async( dispatch_get_main_queue(), ^{
#warning Resume button disabled
                    //self.resumeButton.hidden = NO;
                } );
            }
        } );
    }
    else {
#warning Resume button disabled
        //self.resumeButton.hidden = NO;
    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification
{
    // In some scenarios we want to enable the user to resume the session running.
    // For example, if music playback is initiated via control center while using AVCam,
    // then the user can let AVCam resume the session running, which will stop music playback.
    // Note that stopping music playback in control center will not automatically resume the session running.
    // Also note that it is not always possible to resume, see -[resumeInterruptedSession:].
    BOOL showResumeButton = NO;
    
    // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
    if ( &AVCaptureSessionInterruptionReasonKey ) {
        AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
        NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
        
        if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
            reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
            showResumeButton = YES;
        }
        else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps ) {
            // Simply fade-in a label to inform the user that the camera is unavailable.
            self.cameraUnavailableLabel.hidden = NO;
            self.cameraUnavailableLabel.alpha = 0.0;
            [UIView animateWithDuration:0.25 animations:^{
                self.cameraUnavailableLabel.alpha = 1.0;
            }];
        }
    }
    else {
        NSLog( @"Capture session was interrupted" );
        showResumeButton = ( [UIApplication sharedApplication].applicationState == UIApplicationStateInactive );
    }
    
    if ( showResumeButton ) {
        // Simply fade-in a button to enable the user to try to resume the session running.
        self.resumeButton.hidden = NO;
        self.resumeButton.alpha = 0.0;
        [UIView animateWithDuration:0.25 animations:^{
            self.resumeButton.alpha = 1.0;
        }];
    }
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
    NSLog( @"Capture session interruption ended" );
    
    if ( ! self.resumeButton.hidden ) {
        [UIView animateWithDuration:0.25 animations:^{
            self.resumeButton.alpha = 0.0;
        } completion:^( BOOL finished ) {
            self.resumeButton.hidden = YES;
        }];
    }
    if ( ! self.cameraUnavailableLabel.hidden ) {
        [UIView animateWithDuration:0.25 animations:^{
            self.cameraUnavailableLabel.alpha = 0.0;
        } completion:^( BOOL finished ) {
            self.cameraUnavailableLabel.hidden = YES;
        }];
    }
}*/








- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backButtonTapped:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)recordButtonTapped:(UIButton *)sender {
    //NSLog(@"Record button tapped");
    [self toggleRecording];
}

- (void)toggleRecording {
    static BOOL currentlyRecording = NO;
    if (!currentlyRecording) {
        // Start recording
        //NSLog(@"Start recording");
        // Animate start -> stop button change
        [self.view layoutIfNeeded];
        self.recordButtonHeightConstraint.constant = 28;
        self.recordButtonWidthConstraint.constant = 28;
        [UIView animateWithDuration:kRecordButtonAnimationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.fromValue = @(self.recordButton.layer.cornerRadius);
        animation.toValue = @(4);
        animation.duration = kRecordButtonAnimationDuration - 0.03;
        [self.recordButton.layer setCornerRadius:4];
        [self.recordButton.layer addAnimation:animation forKey:@"cornerRadius"];
        
        currentlyRecording = YES;
        
    } else {
        // Stop recording
        //NSLog(@"Stop recording");
        // Animate stop -> start button change
        [self.view layoutIfNeeded];
        self.recordButtonHeightConstraint.constant = 50;
        self.recordButtonWidthConstraint.constant = 50;
        [UIView animateWithDuration:kRecordButtonAnimationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.fromValue = @(self.recordButton.layer.cornerRadius);
        animation.toValue = @(25);
        animation.duration = kRecordButtonAnimationDuration - 0.1;
        animation.beginTime = CACurrentMediaTime() + 0.05f;
        
        double delayInSeconds = 0.06;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //code to be executed on the main queue after delay
            [self.recordButton.layer setCornerRadius:25];
        });
        [self.recordButton.layer addAnimation:animation forKey:@"cornerRadius"];
        
        currentlyRecording = NO;
    }
}

- (void)loadView {
    UIView *view = [[UIView alloc] init];
    self.view = view;
    
    view.backgroundColor = [UIColor blackColor];
    
    // Top view
    UIView *topView = [[UIView alloc] init];
    topView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:topView];
    // Appearance
    topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.35];
    topView.opaque = NO;
    
    // Top view timer label
    UILabel *timerLabel = [[UILabel alloc] init];
    timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [topView addSubview:timerLabel];
    self.timerLabel = timerLabel;
    // Appearance
    timerLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightLight];
    timerLabel.textColor = [UIColor whiteColor];
    // Content
    timerLabel.text = @"00:00";
    
    // Top view AUTOLAYOUT
    [topView addConstraint:[NSLayoutConstraint constraintWithItem:timerLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:topView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[timerLabel]-10-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(timerLabel)]];
    
    // Bottom views
    UIView *bottomView = [[UIView alloc] init];
    bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bottomView];
    // Appearance
    bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.35];
    bottomView.opaque = NO;
    
    // Bottom view record button decal
    UIImageView *recordButtonDecal = [[UIImageView alloc] init];
    recordButtonDecal.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomView addSubview:recordButtonDecal];
    // Appearance
    [recordButtonDecal setImage:[UIImage imageNamed:@"record-button-decal"]];
    
    // Bottom view record button
    UIButton *recordButton = [[UIButton alloc] init];
    recordButton.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomView addSubview:recordButton];
    self.recordButton = recordButton;
    [recordButton addTarget:self action:@selector(recordButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    // Appearance
    recordButton.backgroundColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1];
    recordButton.layer.cornerRadius = 25.0f; // make it a circle!
    // Size
    NSLayoutConstraint *recordButtonHeightConstraint = [NSLayoutConstraint constraintWithItem:recordButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50.0f];
    [recordButton addConstraint:recordButtonHeightConstraint];
    self.recordButtonHeightConstraint = recordButtonHeightConstraint;
    
    NSLayoutConstraint *recordButtonWidthConstraint = [NSLayoutConstraint constraintWithItem:recordButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50.0f];
    [recordButton addConstraint:recordButtonWidthConstraint];
    self.recordButtonWidthConstraint = recordButtonWidthConstraint;
    
    // Bottom view back button
    UIButton *backButton = [[UIButton alloc] init];
    backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomView addSubview:backButton];
    [backButton addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    // Appearance
    [backButton setImage:[UIImage imageNamed:@"left arrow"] forState:UIControlStateNormal];
    
    // Bottom view AUTOLAYOUT
    [recordButton.centerXAnchor constraintEqualToAnchor:bottomView.centerXAnchor].active = YES;
    [recordButton.centerYAnchor constraintEqualToAnchor:bottomView.centerYAnchor].active = YES;
    
    [recordButtonDecal.centerXAnchor constraintEqualToAnchor:bottomView.centerXAnchor].active = YES;
    [recordButtonDecal.centerYAnchor constraintEqualToAnchor:bottomView.centerYAnchor].active = YES;
    
    [backButton.centerYAnchor constraintEqualToAnchor:bottomView.centerYAnchor].active = YES;
    [bottomView addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:bottomView attribute:NSLayoutAttributeLeading multiplier:1 constant:26]];
    
    // Notification view
    UIView *notificationView = [[UIView alloc] init];
    notificationView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:notificationView];
    // Appearance
    notificationView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.60];
    
    // Notification label
    UILabel *notificationLabel = [[UILabel alloc] init];
    notificationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [notificationView addSubview:notificationLabel];
    // Appearance
    notificationLabel.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"TAP TO BEGIN"];
    [attributedString addAttribute:NSKernAttributeName
                             value:@(1.0f)
                             range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular]
                             range:NSMakeRange(0, attributedString.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:[UIColor whiteColor]
                             range:NSMakeRange(0, attributedString.length)];
    [notificationLabel setAttributedText:attributedString];
    
    // Notification view AUTOLAYOUT
    [notificationView addConstraint:[NSLayoutConstraint constraintWithItem:notificationLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:notificationView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [notificationView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[notificationLabel]-6-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(notificationLabel)]];
    
    // Resume Button
    UIButton *resumeButton = [[UIButton alloc] init];
    resumeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:resumeButton];
    self.resumeButton = resumeButton;
    // Appearance
    [resumeButton setTitle:@"Tap to Resume" forState:UIControlStateNormal];
    resumeButton.titleLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightSemibold];
    [resumeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    resumeButton.hidden = YES;
    
    // Unavailable label
    UILabel *unavailableLabel = [[UILabel alloc] init];
    unavailableLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:unavailableLabel];
    self.cameraUnavailableLabel = unavailableLabel;
    // Appearance
    unavailableLabel.text = @"Camera Unavailable";
    unavailableLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    unavailableLabel.textColor = [UIColor whiteColor];
    unavailableLabel.hidden = YES;
    
    // AUTOLAYOUT
    NSDictionary *views = NSDictionaryOfVariableBindings(topView,notificationView,bottomView);
    
    [topView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
    [topView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
    [topView.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
    
    NSArray *bottomVLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[notificationView][bottomView(97)]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views];
    [view addConstraints:bottomVLayoutConstraints];
    
    [notificationView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
    [notificationView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
    
    [bottomView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor].active = YES;
    [bottomView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor].active = YES;
    
    // Resume button layout
    UILayoutGuide *unavailableTopLayoutGuide = [[UILayoutGuide alloc] init];
    UILayoutGuide *unavailableBottomLayoutGuide = [[UILayoutGuide alloc] init];
    [view addLayoutGuide:unavailableTopLayoutGuide];
    [view addLayoutGuide:unavailableBottomLayoutGuide];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:unavailableTopLayoutGuide attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:unavailableBottomLayoutGuide attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:unavailableTopLayoutGuide attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:unavailableBottomLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[unavailableTopLayoutGuide][unavailableLabel][unavailableBottomLayoutGuide]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(unavailableTopLayoutGuide, unavailableLabel, unavailableBottomLayoutGuide)]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:unavailableLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    // Resume button layout
    UILayoutGuide *resumeTopLayoutGuide = [[UILayoutGuide alloc] init];
    UILayoutGuide *resumeBottomLayoutGuide = [[UILayoutGuide alloc] init];
    [view addLayoutGuide:resumeTopLayoutGuide];
    [view addLayoutGuide:resumeBottomLayoutGuide];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:resumeTopLayoutGuide attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:resumeBottomLayoutGuide attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:resumeTopLayoutGuide attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:resumeBottomLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[resumeTopLayoutGuide][resumeButton][resumeBottomLayoutGuide]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(resumeTopLayoutGuide, resumeButton, resumeBottomLayoutGuide)]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:resumeButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    
}

@end
