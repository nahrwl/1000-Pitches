//
//  CameraViewController.m
//  MobilePitch
//
//  Created by Nathan Wallace on 10/24/15.
//  Copyright © 2015 Spark Dev Team. All rights reserved.
//
//  Much of this code was taken from Apple's AVCam demo.

@import AVFoundation;
@import Photos;

#import "CameraViewController.h"
#import "AccessRequestViewController.h"
#import "AAPLPreviewView.h"

#define kStatusViewAnimationDuration 1.0f
#define kRecordButtonAnimationDuration 0.2f

static void * SessionRunningContext = &SessionRunningContext;

typedef NS_ENUM(NSInteger, CamSetupResult) {
    CamSetupResultSuccess,
    CamSetupResultCameraNotAuthorized,
    CamSetupResultMicrophoneNotAuthorized, //implicit that if the camera is not authorized, then the microphone isn't either
    CamSetupResultSessionConfigurationFailed
};

typedef NS_ENUM(NSInteger, RecordingStatus) {
    RecordingStatusNotRecording,
    RecordingStatusTooShort,
    RecordingStatusNominal,
    RecordingStatusTooLong,
    RecordingStatusPaused,
    RecordingStatusError
};

@interface CameraViewController () <AVCaptureFileOutputRecordingDelegate, AccessRequestViewControllerDelegate>

// Views
@property (weak, nonatomic) AAPLPreviewView     *previewView;
@property (weak, nonatomic) UILabel             *timerLabel;
@property (weak, nonatomic) UILabel             *statusLabel;
@property (weak, nonatomic) UIView              *statusView;
@property (weak, nonatomic) UILabel             *cameraUnavailableLabel;
@property (weak, nonatomic) UIView              *permissionsErrorView;
@property (weak, nonatomic) UILabel             *permissionsTitleLabel;
@property (weak, nonatomic) UILabel             *permissionsDescriptionLabel;
@property (weak, nonatomic) UIButton            *permissionsButton;
@property (weak, nonatomic) UIButton            *resumeButton;
@property (weak, nonatomic) UIButton            *recordButton;
@property (weak, nonatomic) NSLayoutConstraint  *recordButtonHeightConstraint;
@property (weak, nonatomic) NSLayoutConstraint  *recordButtonWidthConstraint;

// Session management
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

// Utilities
@property (nonatomic) CamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic) RecordingStatus recordingStatus;

// Timing
@property (strong, nonatomic) NSDate *startDate;
@property (weak, nonatomic) NSTimer *timer;

// Methods
- (void)backButtonTapped:(UIButton *)sender;

@end

@implementation CameraViewController

#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Disable UI. The UI is enabled if and only if the session starts running.
    self.recordButton.enabled = NO;
    
    // Create the AVCaptureSession.
    self.session = [[AVCaptureSession alloc] init];
    
    // Setup the preview view.
    self.previewView.session = self.session;
    
    // Communicate with the session and other session objects on this queue.
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    
    [self setup];
}

- (void)setup {
    self.setupResult = CamSetupResultSuccess;
    
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            // Now check for microphone authorization
            switch ([[AVAudioSession sharedInstance] recordPermission]) {
                case AVAudioSessionRecordPermissionGranted:
                {
                    // We all good baby
                    break;
                }
                    
                case AVAudioSessionRecordPermissionUndetermined:
                {
                    // The user has not yet been presented with the option to grant audio access.
                    // We suspend the session queue to delay session setup until the access request has completed to avoid
                    // completing the session dispatch tasks before the user gives permission.
                    // Video permission has already been granted.
                    dispatch_suspend( self.sessionQueue ); //IMPORTANT
                    
                    AccessRequestViewController *arvc = [[AccessRequestViewController alloc] init];
                    arvc.delegate = self; //EVEN MORE IMPORTANT YOU DUMBO
                    arvc.modalPresentationStyle = UIModalPresentationOverFullScreen;
                    double delayInSeconds = 0.5;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        //code to be executed on the main queue after delay
                        [self presentViewController:arvc animated:YES completion:nil];
                    });
                    self.setupResult = CamSetupResultMicrophoneNotAuthorized;
                    break;
                }
                    
                default:
                {
                    break;
                }
            }
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session setup until the access request has completed to avoid
            // asking the user for audio access if video access is denied.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend( self.sessionQueue ); //IMPORTANT
            
            AccessRequestViewController *arvc = [[AccessRequestViewController alloc] init];
            arvc.delegate = self; //EVEN MORE IMPORTANT YOU DUMBO
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
        
        AVCaptureDevice *videoDevice = [CameraViewController deviceWithMediaType:AVMediaTypeVideo
                                                              preferringPosition:AVCaptureDevicePositionFront];
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
    } );
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self begin];
}

- (void)begin {
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
                    [self togglePermissionsErrorViewForHardware:@"camera"];
                } );
                break;
            }
            case CamSetupResultMicrophoneNotAuthorized:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    [self togglePermissionsErrorViewForHardware:@"microphone"];
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
    } );
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

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

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
                    self.resumeButton.hidden = NO;
                } );
            }
        } );
    }
    else {
        self.resumeButton.hidden = NO;
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
}

#pragma mark Actions

- (IBAction)resumeInterruptedSession:(id)sender
{
    dispatch_async( self.sessionQueue, ^{
        // The session might fail to start running, e.g., if a phone or FaceTime call is still using audio or video.
        // A failure to start the session running will be communicated via a session runtime error notification.
        // To avoid repeatedly failing to start the session running, we only try to restart the session running in the
        // session runtime error handler if we aren't trying to resume the session running.
        [self.session startRunning];
        self.sessionRunning = self.session.isRunning;
        if ( ! self.session.isRunning ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                NSString *message = NSLocalizedString( @"Unable to resume", @"Alert message when unable to resume the session running" );
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:cancelAction];
                [self presentViewController:alertController animated:YES completion:nil];
            } );
        }
        else {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.resumeButton.hidden = YES;
            } );
        }
    } );
}

- (IBAction)toggleMovieRecording:(id)sender
{
    // Disable the Camera button until recording finishes, and disable the Record button until recording starts or finishes. See the
    // AVCaptureFileOutputRecordingDelegate methods.
    self.recordButton.enabled = NO;
    
    dispatch_async( self.sessionQueue, ^{
        if ( ! self.movieFileOutput.isRecording ) {
            if ( [UIDevice currentDevice].isMultitaskingSupported ) {
                // Setup background task. This is needed because the -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
                // callback is not received until AVCam returns to the foreground unless you request background execution time.
                // This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                // To conclude this background execution, -endBackgroundTask is called in
                // -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
                self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
            }
            
            // Update the orientation on the movie file output video connection before starting recording.
            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
            connection.videoOrientation = previewLayer.connection.videoOrientation;
            
            // Start recording to a temporary file.
            NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
            [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
        }
        else {
            [self.movieFileOutput stopRecording];
        }
    } );
}
#warning Create this gesture recognizer!
- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.previewView.layer captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:gestureRecognizer.view]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)backButtonTapped:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)settingsButtonTapped:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

#pragma mark Timing
- (void)timerAction {
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:self.startDate];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    NSString *timeString = [dateFormatter stringFromDate:timerDate];
    self.timerLabel.text = timeString;
    
    if (timeInterval > 180) {
        if (self.recordingStatus != RecordingStatusTooLong) {
            [self setStatusViewRecordingStatus:RecordingStatusTooLong animated:YES];
        }
    } else if (timeInterval > 30) {
        if (self.recordingStatus != RecordingStatusNominal) {
            [self setStatusViewRecordingStatus:RecordingStatusNominal animated:YES];
        }
    } else if (timeInterval > 0) {
        if (self.recordingStatus != RecordingStatusTooShort) {
            [self setStatusViewRecordingStatus:RecordingStatusTooShort animated:YES];
        }
    }
}

- (void)setStatusViewRecordingStatus:(RecordingStatus)status animated:(BOOL)animated {
    
    self.recordingStatus = status;
    
    void (^updateStatus)() = ^ {
        NSString *textString;
        switch (status) {
            case RecordingStatusNotRecording:
                self.statusView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
                textString = @"TAP TO BEGIN";
                break;
                
            case RecordingStatusTooShort:
                self.statusView.backgroundColor = [UIColor colorWithRed:0.718 green:0 blue:0 alpha:0.6];
                textString = @"TOO SHORT";
                break;
                
            case RecordingStatusNominal:
                self.statusView.backgroundColor = [UIColor colorWithRed:0.00392 green:0.588 blue:0.0471 alpha:0.6];
                textString = @"GOOD LENGTH";
                break;
                
            case RecordingStatusTooLong:
                self.statusView.backgroundColor = [UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:0.6];
                textString = @"WRAP IT UP";
                break;
                
            case RecordingStatusPaused:
                self.statusView.backgroundColor = [UIColor colorWithRed:0.718 green:0 blue:0 alpha:0.6];
                textString = @"RECORDING IS PAUSED";
                break;
                
            default:
                self.statusView.backgroundColor = [UIColor colorWithRed:0.718 green:0 blue:0 alpha:0.0];
                textString = @"";
                break;
        }
        self.statusLabel.textAlignment = NSTextAlignmentCenter;
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:textString];
        [attributedString addAttribute:NSKernAttributeName
                                 value:@(1.0f)
                                 range:NSMakeRange(0, attributedString.length)];
        [attributedString addAttribute:NSFontAttributeName
                                 value:[UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular]
                                 range:NSMakeRange(0, attributedString.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:[UIColor whiteColor]
                                 range:NSMakeRange(0, attributedString.length)];
        [self.statusLabel setAttributedText:attributedString];
    };
    
    if (animated) {
        [UIView animateWithDuration:kStatusViewAnimationDuration / 2.0 animations:^{
            self.statusView.alpha = 0;
        } completion:^(BOOL finished) {
            // Fade in
            [UIView animateWithDuration:kStatusViewAnimationDuration / 2.0 animations:^{
                updateStatus();
                self.statusView.alpha = 1.0;
            }];
        }];
        
    } else {
        updateStatus();
    }
}

#pragma mark File Output Recording Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    // Enable the Record button to let the user stop the recording.
    dispatch_async( dispatch_get_main_queue(), ^{
        self.recordButton.enabled = YES;
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
        
        // Begin the timer
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        self.startDate = [NSDate date];
        self.timerLabel.text = @"00:00";
    });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    // Note that currentBackgroundRecordingID is used to end the background task associated with this recording.
    // This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's isRecording property
    // is back to NO — which happens sometime after this method returns.
    // Note: Since we use a unique file path for each recording, a new recording will not overwrite a recording currently being saved.
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
    dispatch_block_t cleanup = ^{
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        if ( currentBackgroundRecordingID != UIBackgroundTaskInvalid ) {
            [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
        }
    };
    
    BOOL success = YES;
    
    if ( error ) {
        NSLog( @"Movie file finishing error: %@", error );
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    if ( success ) {
        // Check authorization status.
        [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
            if ( status == PHAuthorizationStatusAuthorized ) {
                // Save the movie file to the photo library and cleanup.
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    // In iOS 9 and later, it's possible to move the file into the photo library without duplicating the file data.
                    // This avoids using double the disk space during save, which can make a difference on devices with limited free disk space.
                    if ( [PHAssetResourceCreationOptions class] ) {
                        PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                        options.shouldMoveFile = YES;
                        PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
                        [changeRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
                    }
                    else {
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
                    }
                } completionHandler:^( BOOL success, NSError *error ) {
                    if ( ! success ) {
                        NSLog( @"Could not save movie to photo library: %@", error );
                    }
                    cleanup();
                }];
            }
            else {
                cleanup();
            }
        }];
    }
    else {
        cleanup();
    }
    
    // Enable the Camera and Record buttons to let the user switch camera and start another recording.
    dispatch_async( dispatch_get_main_queue(), ^{
        self.recordButton.enabled = YES;
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
        
        //Disable timer
        [self.timer invalidate];
        [self setStatusViewRecordingStatus:RecordingStatusNotRecording animated:YES];
    });
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
            // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

#pragma mark Access Request Delegate

- (void)updateAuthorizationStatusForCam:(BOOL)cam andMicrophone:(BOOL)microphone{
    if (cam && microphone) {
        self.setupResult = CamSetupResultSuccess;
    } else if (!cam) {
        self.setupResult = CamSetupResultCameraNotAuthorized;
    } else if (!microphone) {
        self.setupResult = CamSetupResultMicrophoneNotAuthorized;
    } else {
        self.setupResult = CamSetupResultSessionConfigurationFailed;
    }
    dispatch_resume(self.sessionQueue);
}

#pragma mark View Setup

- (void)togglePermissionsErrorViewForHardware:(NSString *)hardware {
    if (self.permissionsErrorView.hidden) {
        if ([[hardware lowercaseString] isEqualToString:@"camera"])
        {
            self.permissionsTitleLabel.text = @"Camera Access Denied";
            self.permissionsDescriptionLabel.text = @"1000 Pitches doesn't have permission to use the camera.\nPlease change your privacy settings.";
        }
        else if ([[hardware lowercaseString] isEqualToString:@"microphone"])
        {
            self.permissionsTitleLabel.text = @"Microphone Access Denied";
            self.permissionsDescriptionLabel.text = @"1000 Pitches doesn't have permission to use the microphone.\nPlease change your privacy settings.";
        }
        else
        {
            //error
        }
        self.permissionsErrorView.hidden = NO;
    } else {
        self.permissionsErrorView.hidden = YES;
    }
}

- (void)loadView {
    UIView *view = [[UIView alloc] init];
    self.view = view;
    
    view.backgroundColor = [UIColor blackColor];
    
    // AAPLPreviewView
    AAPLPreviewView *previewView = [[AAPLPreviewView alloc] init];
    previewView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:previewView];
    self.previewView = previewView;
    // Autolayout for the previewView
    [previewView.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
    [previewView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
    [previewView.leftAnchor constraintEqualToAnchor:view.leftAnchor].active = YES;
    [previewView.rightAnchor constraintEqualToAnchor:view.rightAnchor].active = YES;
    
    // Top view
    UIView *topView = [[UIView alloc] init];
    topView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:topView];
    // Appearance
    topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.50];
    topView.opaque = NO;
    
    // Top view timer label
    UILabel *timerLabel = [[UILabel alloc] init];
    timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [topView addSubview:timerLabel];
    self.timerLabel = timerLabel;
    // Appearance
    timerLabel.font = [UIFont monospacedDigitSystemFontOfSize:19.0f weight:UIFontWeightLight];
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
    bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.50];
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
    [recordButton addTarget:self action:@selector(toggleMovieRecording:) forControlEvents:UIControlEventTouchUpInside];
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
    [bottomView addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50.0f]];
    [bottomView addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50.0f]];
    
    
    [recordButton.centerXAnchor constraintEqualToAnchor:bottomView.centerXAnchor].active = YES;
    [recordButton.centerYAnchor constraintEqualToAnchor:bottomView.centerYAnchor].active = YES;
    
    [recordButtonDecal.centerXAnchor constraintEqualToAnchor:bottomView.centerXAnchor].active = YES;
    [recordButtonDecal.centerYAnchor constraintEqualToAnchor:bottomView.centerYAnchor].active = YES;
    
    [backButton.centerYAnchor constraintEqualToAnchor:bottomView.centerYAnchor].active = YES;
    [bottomView addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:bottomView attribute:NSLayoutAttributeLeading multiplier:1 constant:7]];
    
    // Notification view
    UIView *notificationView = [[UIView alloc] init];
    notificationView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:notificationView];
    self.statusView = notificationView;
    // Appearance
    // Appearance is handled below with setStatusViewRecordingStatus:animated:
    
    // Notification label
    UILabel *notificationLabel = [[UILabel alloc] init];
    notificationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [notificationView addSubview:notificationLabel];
    self.statusLabel = notificationLabel;
    // Appearance
    [self setStatusViewRecordingStatus:RecordingStatusNotRecording animated:NO];
    
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
    
    // --
    // PERMISSIONS ERROR VIEW EVERYTHING
    UIView *permissionsView = [[UIView alloc] init];
    permissionsView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:permissionsView];
    [view bringSubviewToFront:permissionsView];
    self.permissionsErrorView = permissionsView;
    permissionsView.hidden = YES;
    permissionsView.userInteractionEnabled = YES;
    
    // Permissions title label
    UILabel *permissionsTitleLabel = [[UILabel alloc] init];
    permissionsTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [permissionsView addSubview:permissionsTitleLabel];
    self.permissionsTitleLabel = permissionsTitleLabel;
    // Appearance
    permissionsTitleLabel.text = @"Camera Access Denied";
    permissionsTitleLabel.font = [UIFont systemFontOfSize:24.0f weight:UIFontWeightSemibold];
    permissionsTitleLabel.textColor = [UIColor whiteColor];
    permissionsTitleLabel.textAlignment = NSTextAlignmentCenter;
    
    // Permissions description label
    UILabel *permissionsDescriptionLabel = [[UILabel alloc] init];
    permissionsDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [permissionsView addSubview:permissionsDescriptionLabel];
    self.permissionsDescriptionLabel = permissionsDescriptionLabel;
    // Appearance
    permissionsDescriptionLabel.text = @"1000 Pitches doesn't have permission to use the camera.\nPlease change your privacy settings.";
    permissionsDescriptionLabel.numberOfLines = 0;
    permissionsDescriptionLabel.font = [UIFont systemFontOfSize:18.0f weight:UIFontWeightLight];
    permissionsDescriptionLabel.textColor = [UIColor whiteColor];
    permissionsDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    
    // Permissions settings button
    UIButton *permissionsButton = [[UIButton alloc] init];
    permissionsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [permissionsView addSubview:permissionsButton];
    [permissionsView bringSubviewToFront:permissionsButton];
    self.permissionsButton = permissionsButton;
    // Appearance
    [permissionsButton setTitle:@"Go To Settings" forState:UIControlStateNormal];
    permissionsButton.titleLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightSemibold];
    [permissionsButton setTitleColor:[UIColor colorWithRed:0.984 green:0.741 blue:0.098 alpha:1] forState:UIControlStateNormal];
    // Action
    [permissionsButton addTarget:self action:@selector(settingsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Perms view autolayout
    UILayoutGuide *permsTopLayoutGuide = [[UILayoutGuide alloc] init];
    UILayoutGuide *permsBottomLayoutGuide = [[UILayoutGuide alloc] init];
    [view addLayoutGuide:permsTopLayoutGuide];
    [view addLayoutGuide:permsBottomLayoutGuide];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:permsTopLayoutGuide attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:permsBottomLayoutGuide attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:permsTopLayoutGuide attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:permsBottomLayoutGuide attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[permsTopLayoutGuide][permissionsView][permsBottomLayoutGuide]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(permsTopLayoutGuide, permissionsView, permsBottomLayoutGuide)]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:permissionsView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[permissionsView]|" options:NSLayoutFormatAlignAllTop metrics:nil views:NSDictionaryOfVariableBindings(permissionsView)]];
    
    NSArray *permsVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[permissionsTitleLabel]-14-[permissionsDescriptionLabel]-50-[permissionsButton]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(permissionsTitleLabel,permissionsDescriptionLabel,permissionsButton)];
    [permissionsView addConstraints:permsVConstraints];
    
    [permissionsView addConstraint:[NSLayoutConstraint constraintWithItem:permissionsTitleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:permissionsView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [permissionsDescriptionLabel addConstraint:[NSLayoutConstraint constraintWithItem:permissionsDescriptionLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:300]];
    
}

@end
