//
//  CameraViewController.m
//  ISOCameraLDE
//
//  Created by Xcode Developer on 6/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

@import AVFoundation;
@import Photos;
@import CoreText;

#import "CameraViewController.h"
#import "CameraView.h"
#import "ScaleSliderLayer.h"

#define DISPATCH_CONFIGURATION_QUEUE_TIMEOUT (1.0 * NSEC_PER_SEC)

typedef NS_ENUM( NSInteger, AVCamManualSetupResult ) {
    AVCamManualSetupResultSuccess,
    AVCamManualSetupResultCameraNotAuthorized,
    AVCamManualSetupResultSessionConfigurationFailed
};

// TO-DO:
// 1. Adjust white balance when torch is toggled
// 2. Add a key-value observer for changes to torch
// 3. Set to highest camera resolution available

@interface CameraViewController () <AVCaptureFileOutputRecordingDelegate>
{
    ScaleSliderLayer *scaleSliderLayer;
}

@property (weak, nonatomic) IBOutlet CameraView *cameraView;
//@property (strong, nonatomic) CameraPropertyDispatchSource *dispatcher;


// Session management
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;

@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

// Utilities
@property (nonatomic) AVCamManualSetupResult setupResult;
//@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@property (strong, nonatomic) dispatch_queue_t device_configuration_queue;
@property (strong, nonatomic) dispatch_semaphore_t device_lock_semaphore;

@end

@implementation CameraViewController

@synthesize videoZoomFactor = _videoZoomFactor, ISO = _ISO, isRecording = _isRecording;

- (void)setVideoZoomFactor:(float)videoZoomFactor
{
    self->_videoZoomFactor = videoZoomFactor;
}

- (float)videoZoomFactor
{
    return [self.videoDevice videoZoomFactor]; //self->_videoZoomFactor;
}
//
//+ (NSSet *)keyPathsForValuesAffectingVideoZoomFactor
//{
//    return [NSSet setWithObject:@"videoZoomFactor"];
//}

- (void)setISO:(float)ISO
{
    self->_ISO = [self.videoDevice ISO];
}

- (float)ISO
{
    return [self.videoDevice ISO]; //self->_ISO;
}

- (void)setIsRecording:(BOOL)isRecording
{
    self->_isRecording = isRecording;
}

- (BOOL)isRecording
{
    return self->_isRecording;
}

#pragma mark View Controller Life Cycle

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.cameraControls.layer addSublayer:[self scaleSliderControlTextLayer]];
    [self.scaleSliderControlTextLayer setBackgroundColor:[UIColor redColor].CGColor];
    
    //    [(ScaleSliderControlView*)self.scaleSliderControlView  setDelegate:(id<ScaleSliderControlViewDelegate>)self];
    [(ScaleSliderOverlayView *)self.scaleSliderOverlayView setDelegate:(id<ScaleSliderOverlayViewDelegate> _Nullable)self];
    
    //    [self.scaleSliderControlView addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    
    CGFloat frameMinX  =    -(CGRectGetMidX(self.scaleSliderScrollView.frame));
    CGFloat frameMaxX  =      CGRectGetMaxX(self.scaleSliderScrollView.frame) + fabs(CGRectGetMidX(self.scaleSliderScrollView.frame));
    CGFloat insetMin   = fabs(CGRectGetMidX(self.scaleSliderScrollView.frame) - CGRectGetMinX(self.scaleSliderScrollView.frame));
    CGFloat insetMax   =     (CGRectGetMaxX(self.scaleSliderScrollView.frame) - CGRectGetMidX(self.scaleSliderScrollView.frame)) * 0.5;
    [self.scaleSliderScrollView setContentInset:UIEdgeInsetsMake(CGRectGetMinY(self.scaleSliderScrollView.frame), insetMin, CGRectGetMaxY(self.scaleSliderScrollView.frame), insetMin)];
    //    [self.scaleSliderScrollView setFrame:self.cameraControls.frame];
}

- (CATextLayer *)scaleSliderControlTextLayer
{
    CATextLayer *tl = self->_scaleSliderControlTextLayer;
    if (!tl)
    {
        tl = [CATextLayer layer];
        
        NSMutableParagraphStyle *centerAlignedParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        centerAlignedParagraphStyle.alignment                = NSTextAlignmentCenter;
        NSDictionary *centerAlignedTextAttributes            = @{NSForegroundColorAttributeName:[UIColor systemYellowColor],
                                                                 NSFontAttributeName:[UIFont systemFontOfSize:14.0],
                                                                 NSParagraphStyleAttributeName:centerAlignedParagraphStyle};
        int value = 0;
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", value]
                                                                               attributes:centerAlignedTextAttributes];
        [tl setOpaque:FALSE];
    [tl setAlignmentMode:kCAAlignmentCenter];
        [tl setWrapped:TRUE];
        tl.string = attributedString;
        
//        CGSize textLayerframeSize = [self suggestFrameSizeWithConstraints:self.cameraControls.layer.bounds.size forAttributedString:attributedString]; // this creates the right size frame now (so work it back in)
//        CGRect buttonFrame = [[self cameraControlButtonRectForCameraProperty:cameraProperty] CGRectValue];
//        CGRect buttonFrameInSuperView = [self.cameraControls convertRect:buttonFrame toView:self.cameraControls];
//
//        CGRect frame = CGRectMake(CGRectGetMidX(buttonFrameInSuperView) - (textLayerframeSize.width / 2.0), textLayerframeSize.height * 1.25, textLayerframeSize.width, textLayerframeSize.height);
        //        CGRect frame = CGRectMake(CGRectGetMidX([[self viewWithTag:[self selectedCameraProperty]] convertRect:[[self selectedCameraPropertyFrame] CGRectValue] toView:self]), /*(CGRectGetMidX([[self selectedCameraPropertyFrame] CGRectValue]).origin.x - ([[self selectedCameraPropertyFrame] CGRectValue].size.width / 2.0)) + 83.0*/, ((((CGRectGetMinY(self.bounds) + CGRectGetMidY(self.bounds)) / 2.0) + 6.0) + textLayerFrameY), 48.0, textLayerframeSize.height);
        CGRect textLayerFrame = CGRectMake(CGRectGetMidX(self.view.frame) - 20.0, CGRectGetMinY(self.view.frame), 40.0, 40);
        [tl setFrame:textLayerFrame];
        self->_scaleSliderControlTextLayer = tl;
    }
    return tl;
    
}

static CameraProperty (^cameraPropertyForSelectedButtonInIBOutletCollection)(NSArray *) = ^ CameraProperty (NSArray * cameraPropertyButtons)
{
    __block CameraProperty cameraProperty = CameraPropertyInvalid;
    [cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton *  _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isSelected = [button isSelected];
        cameraProperty = (isSelected) ? [button tag] : CameraPropertyInvalid;
        *stop = isSelected;
    }];
    
    return cameraProperty;
};

static UIButton * (^selectedButtonInIBOutletCollection)(NSArray *) = ^ UIButton *(NSArray * cameraPropertyButtons)
{
    __block UIButton * selectedButton = nil;
    [cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton *  _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isSelected = [button isSelected];
        if (isSelected) selectedButton = button;
        *stop = isSelected;
    }];
    
    return selectedButton;
};

static UIButton * (^requestButtonInIBOutletCollectionWithCameraProperty)(NSArray *, CameraProperty) = ^ UIButton *(NSArray * cameraPropertyButtons, CameraProperty property)
{
    __block UIButton * requestedButton = nil;
    [cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton *  _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL cameraPropertiesMatch = ((CameraProperty)[button tag] == property) ? TRUE : FALSE;
        if (cameraPropertiesMatch) requestedButton = button;
        *stop = cameraPropertiesMatch;
    }];
    
    return requestedButton;
};

//- (void)connectTouchUpInsideEventHandlerToCameraPropertyButtons:(NSArray <UIButton *> *)cameraPropertyButtons
//{
//    [cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton *  _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
//        [button targetForAction:@selector(cameraPropertyButtonEventHandler:forEvent:) withSender:button];
//    }];
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //    [self.cameraControlsContainerView setDelegate:(id<CameraControlsDelegate> _Nullable)self];
    
    // Create the AVCaptureSession
    self.session = [[AVCaptureSession alloc] init];
    
    // Create a device discovery session
    NSArray<NSString *> *deviceTypes = @[AVCaptureDeviceTypeBuiltInDualCamera];
    self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    
    // Set up the preview view
    self.cameraView.session = self.session;
    
    // Communicate with the session and other session objects on this queue
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    
    self.setupResult = AVCamManualSetupResultSuccess;
    
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session running until the access request has completed.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = AVCamManualSetupResultCameraNotAuthorized;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        default:
        {
            // The user has previously denied access
            self.setupResult = AVCamManualSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    // Setup the capture session.
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
    // so that the main queue isn't blocked, which keeps the UI responsive.
    dispatch_async( self.sessionQueue, ^{
        [self configureSession];
    } );
}

- (void)configureSession
{
    if ( self.setupResult != AVCamManualSetupResultSuccess ) {
        return;
    }
    
    void(^session_error_cleanup)(NSString *) = ^(NSString *error_description)
    {
        //NSLog(@"Error configuring session: %@", error_description);
        self.setupResult = AVCamManualSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    };
    
    [self.session beginConfiguration];
    
    self.session.sessionPreset = AVCaptureSessionPreset3840x2160;
    
    // Add video input
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    __autoreleasing NSError *error = nil;
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (!videoDeviceInput) return session_error_cleanup(error.description);
    
    if ([self.session canAddInput:videoDeviceInput])
    {
        [self.session addInput:videoDeviceInput];
        self.videoDeviceInput = videoDeviceInput;
        self.videoDevice = videoDevice;
        
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        
        if ([self.session canAddOutput:movieFileOutput])
        {
            [self.session addOutput:movieFileOutput];
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if ( connection.isVideoStabilizationSupported ) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            self.movieFileOutput = movieFileOutput;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
            if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
            }
            
            AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.cameraView.layer;
            previewLayer.connection.videoOrientation = initialVideoOrientation;
        });
    } else {
        return session_error_cleanup(@"Error while adding device input connection.");
    }
    
    // Add audio input
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (!audioDeviceInput) return session_error_cleanup(error.description);
    
    if ([self.session canAddInput:audioDeviceInput]) {
        [self.session addInput:audioDeviceInput];
    } else {
        return session_error_cleanup(error.description);
    }
    
    [self.session commitConfiguration];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async( self.sessionQueue, ^{
        switch ( self.setupResult )
        {
            case AVCamManualSetupResultSuccess:
            {
                //                [self addObservers];
                [self.session startRunning];
                //                self.sessionRunning = self.session.isRunning;
                if (self.session.isRunning)
                {
                    [self lockDevice];
                    [self configureCameraForHighestFrameRateWithCompletionHandler:^(NSString *error_description) {
                        if (error_description)
                        {
                            //NSLog(@"Error configuring camera for highest frame rate: %@", error_description);
                        }
                        [self autoExposureWithCompletionHandler:^(double ISO) {
                            [self autoFocusWithCompletionHandler:^(double focus) {
                                
                            }];
                        }];
                    }];
                } else {
                    //NSLog(@"Session is running");
                }
                break;
            }
            case AVCamManualSetupResultCameraNotAuthorized:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"AVCamManual doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCamManual" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            case AVCamManualSetupResultSessionConfigurationFailed:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCamManual" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
        }
    } );
}

//- (void)configureCamera
//{
//    dispatch_async( self.sessionQueue, ^{
//        @try {
//            [self autoExposureWithCompletionHandler:^(double ISO) {
//                if ( [self.videoDevice isExposureModeSupported:AVCaptureExposureModeCustom] ) {
//                    self.videoDevice.exposureMode = AVCaptureExposureModeCustom;
//                    CMTime exposureDuration = CMTimeMake(self.videoDevice.exposureDuration.value, self.videoDevice.exposureDuration.timescale);
//                    [self.videoDevice setExposureModeCustomWithDuration:exposureDuration /*CMTimeMakeWithSeconds((1.0/3.0), 1000*1000*1000)*/ ISO:[self valueForCameraProperty:CameraPropertyISO] completionHandler:nil];
//                }
//                else {
//                    //NSLog( @"Exposure mode AVCaptureExposureModeCustom is not supported.");
//                }
//                [self configureCameraForHighestFrameRate:self.videoDevice];
//            }];
//            [self autoFocusWithCompletionHandler:^(double focus) {
//                __autoreleasing NSError *error = nil;
//                if ( [self.videoDevice lockForConfiguration:&error] ) {
//                    if ( [self.videoDevice isFocusModeSupported:AVCaptureFocusModeLocked] ) {
//                        self.videoDevice.focusMode = AVCaptureFocusModeLocked;
//                        self.videoDevice.smoothAutoFocusEnabled = FALSE;
//                    }
//                    else {
//                        //NSLog( @"Focus mode AVCaptureFocusModeLocked is not supported.");
//                    }
//                }
//                else {
//                    //NSLog( @"Could not lock device for configuration: %@", error );
//                }
//            }];
//        } @catch (NSException *exception) {
//            //NSLog( @"Error setting exposure mode to AVCaptureExposureModeCustom:\t%@\n%@.", error.description, exception.description);
//        } @finally {
//            [self lockDevice];
//        }
//    });
//}

- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == AVCamManualSetupResultSuccess ) {
            [self.session stopRunning];
            //            [self removeObservers];
        }
    } );
    
    [super viewDidDisappear:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.cameraView.layer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    // Disable autorotation of the interface when recording is in progress
    return FALSE;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark HUD

//- (void)configureManualHUD
//{
//    if (self.videoDevice != nil)
//    {
//
//        {
//            self.ISOSlider.minimumValue = self.videoDevice.activeFormat.minISO;
//            self.ISOSlider.maximumValue = self.videoDevice.activeFormat.maxISO;
//            self.ISOSlider.value = self.videoDevice.ISO;
//if ( &&
//([self.videoDevice isExposureModeSupported:AVCaptureExposureModeCustom] && self.videoDevice.exposureMode == AVCaptureExposureModeCustom))
//            self.ISOSlider.enabled = ( self.videoDevice.exposureMode == AVCaptureExposureModeCustom );
//        }
//    }
//
//
//}

#pragma mark Session Management

// Should be called on the session queue

- (IBAction)resumeInterruptedSession:(id)sender
{
    dispatch_async( self.sessionQueue, ^{
        // The session might fail to start running, e.g. if a phone or FaceTime call is still using audio or video.
        // A failure to start the session will be communicated via a session runtime error notification.
        // To avoid repeatedly failing to start the session running, we only try to restart the session in the
        // session runtime error handler if we aren't trying to resume the session running.
        [self.session startRunning];
        //        self.sessionRunning = self.session.isRunning;
        if ( ! self.session.isRunning ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                NSString *message = NSLocalizedString( @"Unable to resume", @"Alert message when unable to resume the session running" );
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCamManual" message:message preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:cancelAction];
                [self presentViewController:alertController animated:YES completion:nil];
            } );
        }
        else {
            dispatch_async( dispatch_get_main_queue(), ^{
                //                self.resumeButton.hidden = YES;
            } );
        }
    } );
}

#pragma mark Device Configuration

- (dispatch_queue_t)device_configuration_queue
{
    dispatch_queue_t dcq = self->_device_configuration_queue;
    if (!dcq) {
        dcq = dispatch_queue_create("device_configuration_queue", DISPATCH_QUEUE_SERIAL); //dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self->_device_configuration_queue = dcq;
    }
    return dcq;
}

- (dispatch_semaphore_t)device_lock_semaphore
{
    dispatch_semaphore_t dls = self->_device_lock_semaphore;
    if (!dls) {
        dls = dispatch_semaphore_create(0);
        self->_device_lock_semaphore = dls;
    }
    
    return dls;
}

// NOTES:

// WAITS can be scheduled first
// WAITS must be in the order of operations
// WAITS are scheduled on a serial queue
// Serial queue operations start with WAIT

// After WAITS are scheduled, the
// SIGNALING and SIGNAL must be in pairs
// All pairs must be in the proper order of operations



// Adds a block to a serial queue (which controls the order in which it is executed) on an asynchronous thread (which allows other blocks to be added to the queue prior to execution of blocks delayed by semaphores)
// The block signals the waiting semaphore (next method)

- (void)lockDevice
{
    //    //NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self.videoDevice unlockForConfiguration];
    
    dispatch_async([self device_configuration_queue], ^{
        dispatch_semaphore_wait([self device_lock_semaphore], DISPATCH_TIME_FOREVER);
        __autoreleasing NSError *error = nil;
        @try {
            if ([self.videoDevice lockForConfiguration:&error])
            {
                dispatch_semaphore_signal([self device_lock_semaphore]);
            }
        } @catch (NSException *exception) {
            //NSLog( @"Could not lock device for configuration: %@\t%@", exception.description, error.description);
        } @finally {
            
        }
    });
}

// Adds a block to a serial queue on an asynchronous thread, which allows subsequent blocks to be added in order to the same queue prior to its execution;
// The block suspends execution using a waiting semaphore
// After queueing the block, a signal semaphore resumes execution of the block in the previous method; that block then signals the waiting semaphore in thie block
- (void)configureCameraForHighestFrameRateWithCompletionHandler:(void (^)(NSString *error_description))completionHandler
{
    dispatch_async([self device_configuration_queue], ^{
        //        //NSLog(@"%s", __PRETTY_FUNCTION__);
        dispatch_semaphore_wait([self device_lock_semaphore], DISPATCH_TIME_FOREVER);
        AVCaptureDeviceFormat *bestFormat = nil;
        AVFrameRateRange *bestFrameRateRange = nil;
        for ( AVCaptureDeviceFormat *format in [self.videoDevice formats] ) {
            for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
                if ( range.maxFrameRate > bestFrameRateRange.maxFrameRate ) {
                    bestFormat = format;
                    bestFrameRateRange = range;
                }
            }
        }
        if ( bestFormat ) {
            
            @try {
                self.videoDevice.activeFormat = bestFormat;
                self.videoDevice.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
                self.videoDevice.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
            } @catch (NSException *exception) {
                if (exception) completionHandler(exception.description);
            } @finally {
                //                    [self lockDevice];
            }
        }
    });
    dispatch_semaphore_signal([self device_lock_semaphore]);
}


- (void)autoFocusWithCompletionHandler:(void (^)(double focus))completionHandler
{
    //    //NSLog(@"%s", __PRETTY_FUNCTION__);
    __autoreleasing NSError *error;
    @try {
        if (![self.videoDevice isAdjustingFocus] && [self.videoDevice lockForConfiguration:&error]) {
            [self.videoDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
    } @catch (NSException *exception) {
        //NSLog( @"ERROR auto-focusing:%@\t%@", exception.description, error.description);
    } @finally {
        [self lockDevice];
        //            while ([self.videoDevice isAdjustingFocus]) {
        //
        //            }
        //            completionHandler([self.videoDevice lensPosition]);
    }
}

- (void)autoExposureWithCompletionHandler:(void (^)(double ISO))completionHandler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //                        //NSLog(@"BLOCK IS WAITING");
        dispatch_semaphore_wait([self device_lock_semaphore], DISPATCH_TIME_FOREVER);
        //                            //NSLog(@"BLOCK IS SIGNALED");
        if (![self.videoDevice isAdjustingExposure]) {
            @try {
                [self.videoDevice setExposureMode:AVCaptureExposureModeAutoExpose];
            } @catch (NSException *exception) {
                //NSLog( @"ERROR auto-focusing:\t%@", exception.description);
            } @finally {
                while ([self.videoDevice isAdjustingExposure]) {
                    
                }
                completionHandler([self.videoDevice ISO]);
                [self lockDevice];
            }
        } else {
            //NSLog( @"Could not lock device for focus configuration: %@", nil );
        }
        dispatch_semaphore_signal([self device_lock_semaphore]);
    });
}

- (void)addObservers
{
    [self addObserver:self forKeyPath:@"videoDevice.lensPosition" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)[NSString stringWithFormat:@"%lu", CameraPropertyLensPosition]];
    [self addObserver:self forKeyPath:@"videoDevice.focusMode" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)[NSString stringWithFormat:@"%lu", CameraPropertyLensPosition]];
    [self addObserver:self forKeyPath:@"ISO" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)[NSString stringWithFormat:@"%lu", CameraPropertyISO]];
    [self addObserver:self forKeyPath:@"videoDevice.torchLevel" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)[NSString stringWithFormat:@"%lu", CameraPropertyTorchLevel]];
    [self addObserver:self forKeyPath:@"videoZoomFactor" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)[NSString stringWithFormat:@"%lu", CameraPropertyVideoZoomFactor]];
    [self addObserver:self forKeyPath:@"videoDevice.exposureDuration" options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)[NSString stringWithFormat:@"%lu", CameraPropertyExposureDuration]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    __block UIButton *button;
    CameraProperty cameraProperty = (CameraProperty)[[self cameraPropertyNumberFormatter] numberFromString:(__bridge NSString * _Nonnull)(context)];
    dispatch_async( dispatch_get_main_queue(), ^{
        button = (UIButton *)[self.view viewWithTag:cameraProperty];
    });
    //    if (cameraProperty == CameraPropertyLensPosition || cameraProperty == CameraPropertyTorchLevel || cameraProperty == CameraPropertyVideoZoomFactor) {
    id newValue = change[NSKeyValueChangeNewKey];
    if (newValue && newValue != [NSNull null]) {
        float newFloatValue;
        if ([(NSObject *)newValue isKindOfClass:[NSNumber class]])
        {
            CMTime newExposureDuration = [newValue CMTimeValue];
            newFloatValue = newExposureDuration.timescale;
        } else {
            if (cameraProperty == CameraPropertyISO)
            {
                newFloatValue = [newValue floatValue];
                float maxISO = self.videoDevice.activeFormat.maxISO;
                float minISO = self.videoDevice.activeFormat.minISO;
                newFloatValue = minISO + (newFloatValue * (maxISO - minISO));
                newFloatValue = normalize(newFloatValue, 0.0, 1.0, minISO, maxISO);
            } else {
                newFloatValue = ([(NSObject *)newValue isKindOfClass:[NSNumber class]]) ? [newValue floatValue] : ([newValue CMTimeValue].timescale);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat frameMinX  = -(CGRectGetMidX(self.scaleSliderScrollView.frame));
            CGFloat frameMaxX  =  CGRectGetMaxX(self.scaleSliderScrollView.frame) + fabs(CGRectGetMidX(self.scaleSliderScrollView.frame));
            CGFloat inset = fabs(CGRectGetMidX(self.scaleSliderScrollView.frame) - CGRectGetMinX(self.scaleSliderScrollView.frame));
            [button setTitle:[NSString stringWithFormat:@"%.1f", newFloatValue] forState:UIControlStateNormal];
            [button setTintColor:[UIColor systemBlueColor]];
        });
    }
    
    dispatch_async( dispatch_get_main_queue(), ^{
        [button setTintColor:[UIColor systemBlueColor]];
    } );
    
    if (!(cameraProperty > 0) && !(cameraProperty < 7))
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        //NSLog(@"Something else observed.");
    }
    
    //NSLog(@"Context: %lu", cameraProperty);
    //    [self displayValuesForCameraControlProperties];
}

//- (dispatch_source_t)set_camera_property_event
//{
//    dispatch_queue_t queue = [[CameraPropertiesDispatcher dispatch] dispatch_source_queue];
//    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
//    
//    __weak __typeof__(CameraViewController *) weakSelf = (CameraViewController *)self;
//    __typeof__(CameraViewController *) (^self_block_param)(__weak __typeof__ (CameraViewController *)) = ^__typeof__(CameraViewController *)(__weak __typeof__ (CameraViewController *) w_self) {
//        __typeof__(CameraViewController *) s_self = w_self;
//        return s_self;
//    };
//    
//    
//    
//    void (^(^event_handler_block_param)(__typeof__(CameraViewController *) (^)(__weak __typeof__ (CameraViewController *))))(void) = ^(__typeof__(CameraViewController *)(^self_block)(__weak __typeof__ (CameraViewController *))) {
//        dispatch_semaphore_signal([self device_lock_semaphore]);
//        return ^{
//            dispatch_async(queue, ^{
//                unsigned long property = dispatch_source_get_data(source);
//                void * value_c = (void *)dispatch_queue_get_specific(queue, (void *)dispatch_source_get_data(source));
//                CFNumberRef value_cf = CFNumberCreate(kCFAllocatorNull, kCFNumberFloatType, value_c);
//                float value = [(__bridge NSNumber *)value_cf floatValue];
//                dispatch_semaphore_wait([self device_lock_semaphore], DISPATCH_TIME_FOREVER);
//                @try {
//                    if ((NSUInteger)property == CameraPropertyLensPosition) {
//                        if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeLocked] && self.videoDevice.focusMode == AVCaptureFocusModeLocked)
//                        {
//                            [self willChangeValueForKey:@"videoDevice.lensPosition"];
//                            BOOL adjustingFocus = [self.videoDevice isAdjustingFocus];
//                            if (adjustingFocus)
//                            {
//                                [self willChangeValueForKey:@"videoDevice.lensPosition"];
//                                
//                                [self.videoDevice setFocusModeLockedWithLensPosition:value completionHandler:^(CMTime syncTime) {
//                                    //                            //NSLog(@"Lens position (%lu) value: %f", property, value);
//                                    
////                                    __weak __typeof__ (CameraViewController *) weakSelf =_ (CameraViewController *)self;
////                                    [self_block(weakSelf) willChangeValueForKey:@"videoDevice.lensPosition"];
//                                }];
//                            }
//                        } else {
//                            // DISABLE LENS POSITION BUTTON
//                        }
//                    } else if (property == CameraPropertyISO) {
//                        if (![self.videoDevice isAdjustingExposure]) {
//                            [self willChangeValueForKey:@"self.ISO"];
//                            float maxISO = self.videoDevice.activeFormat.maxISO;
//                            float minISO = self.videoDevice.activeFormat.minISO;
//                            float ISO = minISO + (value * (maxISO - minISO));
//                            ISO = ((ISO > minISO) && (ISO < maxISO)) ? ISO : self.videoDevice.ISO;
//                            //                            ISO = (1.0 - 0.0) * (ISO - minISO) / (maxISO - minISO) + 0.0;
//                            [self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:ISO completionHandler:^(CMTime syncTime) {
//                                self_block(@"self.ISO");
//                                //                                //NSLog(@"ISO (%lu) value: %f", property, value);
//                            }];
//                            //                        [self setISO:self.videoDevice.ISO];
//                            
//                        }
//                        
//                        
//                    } else if (property == CameraPropertyTorchLevel && ([[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateCritical && [[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateSerious)) {
//                        [self willChangeValueForKey:@"videoDevice.torchLevel"];
//                        if (value != 0)
//                            [self->_videoDevice setTorchModeOnWithLevel:value error:nil];
//                        else
//                            [self->_videoDevice setTorchMode:AVCaptureTorchModeOff];
//                        
//                        [self didChangeValueForKey:@"videoDevice.torchLevel"];
//                        //                    //NSLog(@"Torch level (%lu) value: %f", property, value);
//                    } else if (property == CameraPropertyVideoZoomFactor) {
//                        if (![self.videoDevice isRampingVideoZoom]) {
//                            [self willChangeValueForKey:@"videoZoomFactor"];
//                            float maxZoom = self.videoDevice.maxAvailableVideoZoomFactor; // self.videoDevice.activeFormat.videoMaxZoomFactor;
//                            float minZoom = self.videoDevice.minAvailableVideoZoomFactor;
//                            float zoomValue = minZoom + (pow(value, 5.0) * (maxZoom - minZoom));
//                            zoomValue = (zoomValue < minZoom) ? minZoom : (zoomValue > maxZoom) ? maxZoom : zoomValue;
//                            //                        zoomValue = 1.0 + (zoomValue * (self.videoDevice.activeFormat.videoMaxZoomFactor - 1.0));
//                            [self.videoDevice setVideoZoomFactor:zoomValue];
//                            [self didChangeValueForKey:@"videoZoomFactor"];
//                            //                        //NSLog(@"Video zoom factor (%lu) value: %f (min: %f\tmax: %f)", property, value, minZoom, maxZoom);
//                        }
//                    } else if (property == CameraPropertyExposureDuration) {
//                        if (![self.videoDevice isAdjustingExposure]) {
//                            [self willChangeValueForKey:@"videoDevice.exposureDuration"];
//                            double minDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration);
//                            double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
//                            // Map from duration to non-linear UI range 0-1
//                            float exposureDuration = minDurationSeconds + (value * (maxDurationSeconds - minDurationSeconds));
//                            //                    //NSLog(@"Exposure duration factor (%lu) value: %f", property, value);
//                            double currentExposureDurationTimeScale = self.videoDevice.exposureDuration.timescale;
//                            CMTime newExposureDuration = CMTimeMakeWithSeconds( exposureDuration, currentExposureDurationTimeScale);
//                            [self.videoDevice setExposureModeCustomWithDuration:newExposureDuration ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
//                                self_block(@"videoDevice.exposureDuration");
//                            }];
//                        }
//                    }
//                } @catch (NSException *exception) {
//                    //NSLog( @"Error configuring device:\t%@", exception.description);
//                } @finally {
//                    
//                }
//            });
//        };
//        
//    };
//    
//    event_handler_block_param(self_block_param(weakSelf));
//    
//    dispatch_source_set_event_handler(source, event_handler_block_param(self_block_param(weakSelf)));
//    //        dispatch_async(queue, ^{
//    //            unsigned long property = dispatch_source_get_data(source);
//    //            void * value_c = (void *)dispatch_queue_get_specific(queue, (void *)dispatch_source_get_data(source));
//    //            CFNumberRef value_cf = CFNumberCreate(kCFAllocatorNull, kCFNumberFloatType, value_c);
//    //            float value = [(__bridge NSNumber *)value_cf floatValue];
//    //            dispatch_semaphore_wait([self device_lock_semaphore], DISPATCH_TIME_FOREVER);
//    //            @try {
//    //                if ((NSUInteger)property == CameraPropertyLensPosition) {
//    //                    if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeLocked] && self.videoDevice.focusMode == AVCaptureFocusModeLocked)
//    //                    {
//    //                        [self willChangeValueForKey:@"videoDevice.lensPosition"];
//    //                        BOOL adjustingFocus = [self.videoDevice isAdjustingFocus];
//    //                        if (adjustingFocus)
//    //                        {
//    //                            [self willChangeValueForKey:@"videoDevice.lensPosition"];
//    //                            [self.videoDevice setFocusModeLockedWithLensPosition:value completionHandler:^(CMTime syncTime) {
//    //                                //                            //NSLog(@"Lens position (%lu) value: %f", property, value);
//    //                                [self didChangeValueForKey:@"videoDevice.lensPosition"];
//    //                            }];
//    //                        }
//    //                    } else {
//    //                        // DISABLE LENS POSITION BUTTON
//    //                    }
//    //                } else if (property == CameraPropertyISO) {
//    //                    if (![self.videoDevice isAdjustingExposure]) {
//    //                        [self willChangeValueForKey:@"self.ISO"];
//    //                        float maxISO = self.videoDevice.activeFormat.maxISO;
//    //                        float minISO = self.videoDevice.activeFormat.minISO;
//    //                        float ISO = minISO + (value * (maxISO - minISO));
//    //                        ISO = ((ISO > minISO) && (ISO < maxISO)) ? ISO : self.videoDevice.ISO;
//    //                        //                            ISO = (1.0 - 0.0) * (ISO - minISO) / (maxISO - minISO) + 0.0;
//    //                        [self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:ISO completionHandler:^(CMTime syncTime) {
//    //                            [self didChangeValueForKey:@"self.ISO"];
//    //                            //                                //NSLog(@"ISO (%lu) value: %f", property, value);
//    //                        }];
//    //                        //                        [self setISO:self.videoDevice.ISO];
//    //
//    //                    }
//    //
//    //
//    //                } else if (property == CameraPropertyTorchLevel && ([[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateCritical && [[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateSerious)) {
//    //                    [self willChangeValueForKey:@"videoDevice.torchLevel"];
//    //                    if (value != 0)
//    //                        [self->_videoDevice setTorchModeOnWithLevel:value error:nil];
//    //                    else
//    //                        [self->_videoDevice setTorchMode:AVCaptureTorchModeOff];
//    //
//    //                    [self didChangeValueForKey:@"videoDevice.torchLevel"];
//    //                    //                    //NSLog(@"Torch level (%lu) value: %f", property, value);
//    //                } else if (property == CameraPropertyVideoZoomFactor) {
//    //                    if (![self.videoDevice isRampingVideoZoom]) {
//    //                        [self willChangeValueForKey:@"videoZoomFactor"];
//    //                        float maxZoom = self.videoDevice.maxAvailableVideoZoomFactor; // self.videoDevice.activeFormat.videoMaxZoomFactor;
//    //                        float minZoom = self.videoDevice.minAvailableVideoZoomFactor;
//    //                        float zoomValue = minZoom + (pow(value, 5.0) * (maxZoom - minZoom));
//    //                        zoomValue = (zoomValue < minZoom) ? minZoom : (zoomValue > maxZoom) ? maxZoom : zoomValue;
//    //                        //                        zoomValue = 1.0 + (zoomValue * (self.videoDevice.activeFormat.videoMaxZoomFactor - 1.0));
//    //                        [self.videoDevice setVideoZoomFactor:zoomValue];
//    //                        [self didChangeValueForKey:@"videoZoomFactor"];
//    //                        //                        //NSLog(@"Video zoom factor (%lu) value: %f (min: %f\tmax: %f)", property, value, minZoom, maxZoom);
//    //                    }
//    //                } else if (property == CameraPropertyExposureDuration) {
//    //                    if (![self.videoDevice isAdjustingExposure]) {
//    //                        [self willChangeValueForKey:@"videoDevice.exposureDuration"];
//    //                        double minDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration);
//    //                        double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
//    //                        // Map from duration to non-linear UI range 0-1
//    //                        float exposureDuration = minDurationSeconds + (value * (maxDurationSeconds - minDurationSeconds));
//    //                        //                    //NSLog(@"Exposure duration factor (%lu) value: %f", property, value);
//    //                        double currentExposureDurationTimeScale = self.videoDevice.exposureDuration.timescale;
//    //                        CMTime newExposureDuration = CMTimeMakeWithSeconds( exposureDuration, currentExposureDurationTimeScale);
//    //                        [self.videoDevice setExposureModeCustomWithDuration:newExposureDuration ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
//    //                            [self didChangeValueForKey:@"videoDevice.exposureDuration"];
//    //                        }];
//    //                    }
//    //                }
//    //            } @catch (NSException *exception) {
//    //                //NSLog( @"Error configuring device:\t%@", exception.description);
//    //            } @finally {
//    //
//    //            }
//    //        });
//    //
//    //        dispatch_semaphore_signal([self device_lock_semaphore]);
//    //    });
//    //    dispatch_set_target_queue(source, queue);
//    //    dispatch_resume(source);
//    //
//    return source;
//}

//- (SetCameraPropertyValueBlock)setCameraPropertyBlock
//{
//    return ^void(CameraProperty property, float value)
//    {
//        dispatch_async([self device_configuration_queue], ^{
//            dispatch_semaphore_wait([self device_lock_semaphore], DISPATCH_TIME_FOREVER);
//            @try {
//                if ( property == CameraPropertyLensPosition) {
//                    BOOL adjustingFocus = [self.videoDevice isAdjustingFocus];
//                    if (adjustingFocus) {
//                        [self willChangeValueForKey:@"videoDevice.lensPosition"];
//                    } else {
//                        [self willChangeValueForKey:@"videoDevice.lensPosition"];
//                        [self.videoDevice setFocusModeLockedWithLensPosition:value completionHandler:^(CMTime syncTime) {
//                            //                            //NSLog(@"Lens position (%lu) value: %f", property, value);
//                            [self didChangeValueForKey:@"videoDevice.lensPosition"];
//                        }];
//                    }
//                } else if (property == CameraPropertyISO) {
//                    if (![self.videoDevice isAdjustingExposure]) {
//                        [self willChangeValueForKey:@"self.ISO"];
//                        float maxISO = self.videoDevice.activeFormat.maxISO;
//                        float minISO = self.videoDevice.activeFormat.minISO;
//                        float ISO = minISO + (value * (maxISO - minISO));
//                        ISO = ((ISO > minISO) && (ISO < maxISO)) ? ISO : self.videoDevice.ISO;
//                        //                            ISO = (1.0 - 0.0) * (ISO - minISO) / (maxISO - minISO) + 0.0;
//                        [self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:ISO completionHandler:^(CMTime syncTime) {
//                            [self didChangeValueForKey:@"self.ISO"];
//                            //                                //NSLog(@"ISO (%lu) value: %f", property, value);
//                        }];
////                        [self setISO:self.videoDevice.ISO];
//
//                    }
//
//
//                } else if (property == CameraPropertyTorchLevel && ([[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateCritical && [[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateSerious)) {
//                    [self willChangeValueForKey:@"videoDevice.torchLevel"];
//                    if (value != 0)
//                        [self->_videoDevice setTorchModeOnWithLevel:value error:nil];
//                    else
//                        [self->_videoDevice setTorchMode:AVCaptureTorchModeOff];
//
//                    [self didChangeValueForKey:@"videoDevice.torchLevel"];
//                    //                    //NSLog(@"Torch level (%lu) value: %f", property, value);
//                } else if (property == CameraPropertyVideoZoomFactor) {
//                    if (![self.videoDevice isRampingVideoZoom]) {
//                        [self willChangeValueForKey:@"videoZoomFactor"];
//                        float maxZoom = self.videoDevice.maxAvailableVideoZoomFactor; // self.videoDevice.activeFormat.videoMaxZoomFactor;
//                        float minZoom = self.videoDevice.minAvailableVideoZoomFactor;
//                        float zoomValue = minZoom + (pow(value, 5.0) * (maxZoom - minZoom));
//                        zoomValue = (zoomValue < minZoom) ? minZoom : (zoomValue > maxZoom) ? maxZoom : zoomValue;
//                        //                        zoomValue = 1.0 + (zoomValue * (self.videoDevice.activeFormat.videoMaxZoomFactor - 1.0));
//                        [self.videoDevice setVideoZoomFactor:zoomValue];
//                        [self didChangeValueForKey:@"videoZoomFactor"];
//                        //                        //NSLog(@"Video zoom factor (%lu) value: %f (min: %f\tmax: %f)", property, value, minZoom, maxZoom);
//                    }
//                } else if (property == CameraPropertyExposureDuration) {
//                    if (![self.videoDevice isAdjustingExposure]) {
//                        [self willChangeValueForKey:@"videoDevice.exposureDuration"];
//                        double minDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration);
//                        double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
//                        // Map from duration to non-linear UI range 0-1
//                        float exposureDuration = minDurationSeconds + (value * (maxDurationSeconds - minDurationSeconds));
//                        //                    //NSLog(@"Exposure duration factor (%lu) value: %f", property, value);
//                        double currentExposureDurationTimeScale = self.videoDevice.exposureDuration.timescale;
//                        CMTime newExposureDuration = CMTimeMakeWithSeconds( exposureDuration, currentExposureDurationTimeScale);
//                        [self.videoDevice setExposureModeCustomWithDuration:newExposureDuration ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
//                            [self didChangeValueForKey:@"videoDevice.exposureDuration"];
//                        }];
//                    }
//                }
//            } @catch (NSException *exception) {
//                //NSLog( @"Error configuring device:\t%@", exception.description);
//            } @finally {
//
//            }
//        }); dispatch_semaphore_signal([self device_lock_semaphore]);
//    };
//}

- (void)selectCameraControlButtonForCameraProperty:(CameraProperty)cameraProperty
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (cameraProperty)
        {
            UIButton *selectedButton = (UIButton *)[self.view viewWithTag:cameraProperty];
            // if the enumerated button and the sender button are the same AND the sender button is not already selected...
            [selectedButton setSelected:TRUE];
            [selectedButton setHighlighted:TRUE];
            //            UIImage *symbol = [[(UIButton *)selectedButton currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleCaption1]];
            //            [(UIButton *)selectedButton setImage:symbol forState:UIControlStateNormal];
            [self.scaleSliderControlView setHidden:FALSE];
            [self.scaleSliderOverlayView setSelectedCameraPropertyValue:[self cameraControlButtonRectForCameraProperty:cameraProperty]];
            [self.scaleSliderOverlayView setNeedsDisplay];
            
            float value = cameraPropertyFunc(self.videoDevice, (CameraProperty)[(UIButton *)selectedButton tag]);
            CGFloat frameMinX  = -(CGRectGetMidX(self.scaleSliderScrollView.frame));
            CGFloat frameMaxX  =  CGRectGetMaxX(self.scaleSliderScrollView.frame) + fabs(CGRectGetMidX(self.scaleSliderScrollView.frame));
            value = normalize(value, 0.0, 10.0, frameMinX, frameMaxX);
            CGFloat inset = fabs(CGRectGetMidX(self.scaleSliderScrollView.frame) - CGRectGetMinX(self.scaleSliderScrollView.frame));
            [self.scaleSliderScrollView setContentInset:UIEdgeInsetsMake(CGRectGetMinY(self.scaleSliderScrollView.frame), inset, CGRectGetMaxY(self.scaleSliderScrollView.frame), inset)];
            //            [self.scaleSliderScrollView setContentOffset:CGPointMake(-CGRectGetMidX(self.scaleSliderScrollView.frame) + ((frameMaxX + frameMinX) * value), 0.0) animated:TRUE];
//            [self setValue:value forCameraControlProperty:cameraProperty];
        }
    });
}

- (void)deselectCameraControlButtonForCameraProperty:(CameraProperty)cameraProperty
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (cameraProperty)
        {
            UIButton *selectedButton = (UIButton *)[self.cameraControls viewWithTag:(!cameraProperty) ? cameraProperty : cameraPropertyForSelectedButtonInIBOutletCollection(self.cameraPropertyButtons)];
            // if the enumerated button and the sender button are the same AND the sender button is not already selected...
            [selectedButton setSelected:FALSE];
            [selectedButton setHighlighted:FALSE];
            //            UIImage *symbol = [[(UIButton *)selectedButton currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleLargeTitle]];
            //            [(UIButton *)selectedButton setImage:symbol forState:UIControlStateNormal];
        }
        [self.scaleSliderControlView setHidden:TRUE];
        [self.scaleSliderOverlayView setNeedsDisplay];
    });
}

- (IBAction)recordButtonEventHandler:(UIButton *)sender forEvent:(UIEvent *)event {
    NSLog(@"Record button touched");
    [self toggleRecordingWithCompletionHandler:^(BOOL isRunning, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [(UIButton *)sender setSelected:isRunning];
            [(UIButton *)sender setHighlighted:isRunning];
        });
    }];
}

- (NSValue *)cameraControlButtonRectForCameraProperty:(CameraProperty)cameraProperty
{
    CGRect cameraControlButtonRect = (CGRect)[(UIButton *)[self.cameraControls viewWithTag:cameraProperty] frame];
    /*CGRectMake(CGRectGetMinX( (CGRect)[(UIButton *)[self viewWithTag:cameraProperty] frame]),
     CGRectGetMinY( (CGRect)[(UIButton *)[self viewWithTag:[self selectedCameraProperty]] frame]),
     CGRectGetWidth((CGRect)[(UIButton *)[self viewWithTag:[self selectedCameraProperty]] frame]),
     CGRectGetHeight((CGRect)[(UIButton *)[self viewWithTag:[self selectedCameraProperty]] frame]));*/
    
    NSValue *selectedCameraPropertyValue = [NSValue valueWithCGRect:cameraControlButtonRect];
    //    //NSLog(@"selectedCameraPropertyFrame (2): %f", selectedCameraPropertyFrame.origin.x);
    
    return selectedCameraPropertyValue;
}

- (UIButton *)selectedCameraControlButton
{
    UIButton *selectedCameraControlButton = (UIButton *)[self.cameraControls viewWithTag:cameraPropertyForSelectedButtonInIBOutletCollection(self.cameraPropertyButtons)];
    
    return selectedCameraControlButton;
}


//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    NSLog(@"CameraViewController\t\t\%s", __PRETTY_FUNCTION__);
//    CameraProperty cameraProperty = (CameraProperty)[[touch gestureRecognizers] indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        BOOL isTapGesture = ([(UIGestureRecognizer *)obj isKindOfClass:[UITapGestureRecognizer class]]) ? TRUE : FALSE;
//        *stop = isTapGesture;
//
//        if ([[touch view] isKindOfClass:[UIButton class]])
//        {
//            NSLog(@"UIButton tapped");
//        } else {
//            NSLog(@"UIButton not tapped");
//        }
//
//        return isTapGesture;
//    }];
//    NSLog(@"Index %lu", cameraProperty);
//    return (cameraProperty < 0.0 || cameraProperty > 7.0) ? FALSE : TRUE;
//    return TRUE;
//}
//
//- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
//{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    if (!self.scaleSliderControlView.isHidden)
//    {
//        [self.cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
//            BOOL isPointInsideButtonRect = CGRectContainsPoint([button frame], point); //([button pointInside:[self convertPoint:point toView:button] withEvent:event]) ? TRUE : FALSE;
//            if (isPointInsideButtonRect)
//            {
//                //                       CameraProperty selectedCameraProperty = [self selectedCameraProperty];
//                //                       CameraProperty buttonTag = (CameraProperty)[button tag];
//                //                       BOOL buttonCameraPropertiesIdentical = (selectedCameraProperty = buttonTag) ? TRUE : FALSE;
//                //                       if (!buttonCameraPropertiesIdentical && ![button isSelected] )
//                [button sendAction:@selector(cameraControlAction:) to:self forEvent:event];
//            } else {
//                switch ((CameraProperty)[button tag]) {
//                    case CameraPropertyRecord:
//                    {
//                        [button sendAction:@selector(recordActionHandler:) to:self forEvent:event];
//                        break;
//                    }
//
//                    default:
//                        break;
//                }
//            }
//            *stop = isPointInsideButtonRect;
//        }];
//    }
//
//
//
//    return TRUE;
//}
//
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//{
//    return YES;
//}

- (IBAction)handleTapGesture:(UITapGestureRecognizer *)sender {
    [self.cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isPointInsideButtonRect = CGRectContainsPoint([obj frame], [sender locationInView:self.cameraControls]);
        if (isPointInsideButtonRect && [(UIButton *)obj isSelected])
            [self cameraPropertyButtonEventHandler:(UIButton *)obj forEvent:nil];
        *stop = isPointInsideButtonRect;
    }];
}


- (void)displayValuesForCameraControlProperties
{
    //    struct CameraProperties cameraProperties;
    //    initCameraProperties(self.delegate, &cameraProperties);
    
    [self.cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            double value = cameraPropertyFunc(self.videoDevice, (CameraProperty)[obj tag]);
            NSString *title = [[self cameraPropertyNumberFormatter] stringFromNumber:[NSNumber numberWithFloat:value]];
            [obj setTitle:title forState:UIControlStateNormal];
            [obj setTintColor:[UIColor systemBlueColor]];
        });
    }];
}

static float (^normalize)(float, float, float, float, float) = ^(float unscaledNum, float minAllowed, float maxAllowed, float min, float max)
{
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
};

static float(^scaleSliderValue)(CGRect, CGFloat, float, float) = ^float(CGRect scrollViewFrame, CGFloat contentOffsetX, float scaleMinimum, float scaleMaximum)
{
    CGFloat frameMinX  = -(CGRectGetMidX(scrollViewFrame));
    CGFloat frameMaxX  =  CGRectGetMaxX(scrollViewFrame) + fabs(CGRectGetMidX(scrollViewFrame));
    contentOffsetX     =  (contentOffsetX < frameMinX) ? frameMinX : ((contentOffsetX > frameMaxX) ? frameMaxX : contentOffsetX);
    float slider_value =  normalize(contentOffsetX, scaleMinimum, scaleMaximum, frameMinX, frameMaxX);
    slider_value       =  (slider_value < scaleMinimum) ? scaleMinimum : (slider_value > scaleMaximum) ? scaleMaximum : slider_value;
    
    return slider_value;
};

- (dispatch_queue_t)textureQueue
{
    __block __typeof__(_textureQueue) q = _textureQueue;
    if (!q)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            q = dispatch_queue_create("_textureQueue", DISPATCH_QUEUE_SERIAL);
            self->_textureQueue = q;
        });
    }
    
    return q;
}

- (dispatch_source_t)textureQueueEvent
{
__block dispatch_source_t dispatch_source = _textureQueueEvent;
dispatch_queue_t dispatch_queue = [self textureQueue];
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    dispatch_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_REPLACE, 0, 0, dispatch_queue);
    dispatch_source_set_event_handler(dispatch_source, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            long value = dispatch_source_get_data(dispatch_source);
            dispatch_source_merge_data([self textureQueueEvent], value);
            [self.lockedCameraPropertyButton setTitle:[NSString stringWithFormat:@"%ld", value] forState:UIControlStateNormal];
        });
//        const char *label = [[NSString stringWithFormat:@"%ld", property] cStringUsingEncoding:NSUTF8StringEncoding];
//        dispatch_async(dispatch_queue, ^{
//            CameraPropertyValue *cameraPropertyValueStruct = (CameraPropertyValue *)dispatch_get_specific(label);
//            if (cameraPropertyValueStruct != NULL)
//            {
//                int value = *(int *)&cameraPropertyValueStruct->cameraPropertyValue;
//
//                free((void *)cameraPropertyValueStruct);
//            }
//        });
    });
    dispatch_set_target_queue(dispatch_source, dispatch_queue);
    dispatch_resume(dispatch_source);
    self->_textureQueueEvent = dispatch_source;
});

return dispatch_source;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    CameraProperty property = (CameraProperty)[self.lockedCameraPropertyButton tag];
//    void * p = &property;
    dispatch_async(dispatch_get_main_queue(), ^{
        long v = (long)(scaleSliderValue(scrollView.frame, scrollView.contentOffset.x, 0.0, 1000.0));
        //    printf("v: %d\n", v);
        //    void * value = &v;
            dispatch_source_merge_data([self textureQueueEvent], v);
        [self.scaleSliderControlTextLayer setString:[NSString stringWithFormat:@"%ld", v]];
    });
    
//    dispatch_queue_set_specific([self textureQueue], p, (void *)value, NULL/*(dispatch_function_t)free*/);
//
    
    //    CameraPropertyValue *cameraPropertyValueStruct = (CameraPropertyValue *)malloc(sizeof(CameraPropertyValue));
    //    if (cameraPropertyValueStruct != NULL)
    //    {
    //        float v = scaleSliderValue(scrollView.frame, scrollView.contentOffset.x, 0.0, 1.0);
    //        void * value = &v;
    //        cameraPropertyValueStruct->cameraPropertyValue = value;
    //        CameraProperty property = CameraPropertyISO;
    //        const char *label = [[NSString stringWithFormat:@"%ld", (long)property] cStringUsingEncoding:NSUTF8StringEncoding];
    //        dispatch_queue_set_specific([self textureQueue], label, cameraPropertyValueStruct, NULL);
    //        dispatch_source_merge_data([self textureQueueEvent], (long)property);
    //    }
    //    dispatch_source_merge_data([[CameraPropertyDispatchSource dispatcher] dispatch_source_value_getter], 1);
    //    dispatch_queue_set_specific(dispatch_get_main_queue(), &CameraPropertyValueKey, CameraPropertyValueKey, NULL);
    
    //    if ((!self.scaleSliderControlView.isHidden && (scrollView.isDragging || scrollView.isTracking || scrollView.isDecelerating)))
    //    {
    //        //        dispatch_async(dispatch_get_main_queue(), ^{
    //        //            UIButton *button = selectedButtonInIBOutletCollection(self.cameraPropertyButtons);
    //        void(^block)(CameraProperty) = ^(CameraProperty property) {
    //            void * p = &property;
    //            float v = scaleSliderValue(scrollView.frame, scrollView.contentOffset.x, 0.0, 1.0);
    //            printf("\np: %lu\tv: %f\n", property, v);
    //            void * value = &v;
    //            dispatch_source_merge_data([[CameraPropertyDispatchSource dispatcher] dispatch_source_value_getter], property);
    //            dispatch_queue_set_specific([[CameraPropertyDispatchSource dispatcher] dispatch_source_queue_value_getter], p, (void *)value, NULL/*(dispatch_function_t)free*/);
    //        };
    //        block(CameraPropertyRecord);
    //
    //        //            [button setTitle:[NSString stringWithFormat:@"%f", value] forState:UIControlStateNormal];
    //        //        });
    //    }
}

- (NSNumberFormatter *)cameraPropertyNumberFormatter
{
    NSNumberFormatter * formatter = [[ NSNumberFormatter alloc ] init ] ;
    [ formatter setFormatWidth:1 ] ;
    [ formatter setPaddingCharacter:@" " ] ;
    [ formatter setFormatterBehavior:NSNumberFormatterBehavior10_4 ] ;
    [ formatter setNumberStyle:NSNumberFormatterNoStyle ] ;
    
    return formatter;
}

double (cameraPropertyFunc)(AVCaptureDevice *videoDevice, CameraProperty cameraProperty)
{
    double cameraPropertyValue;
    switch (cameraProperty) {
        case CameraPropertyExposureDuration:
        {
            cameraPropertyValue = (double)videoDevice.exposureDuration.value;
            break;
        }
        case CameraPropertyISO:
        {
            cameraPropertyValue = (double)videoDevice.ISO;
            break;
        }
        case CameraPropertyLensPosition:
        {
            cameraPropertyValue = (double)videoDevice.lensPosition;
            break;
        }
        case CameraPropertyTorchLevel:
        {
            cameraPropertyValue = (double)videoDevice.torchLevel;
            break;
        }
        case CameraPropertyVideoZoomFactor:
        {
            cameraPropertyValue = (double)videoDevice.videoZoomFactor;
            break;
        }
            
        default:
        {
            cameraPropertyValue = 5.0;
            break;
        }
    }
    
    return cameraPropertyValue;
}

- (CGSize)suggestFrameSizeWithConstraints:(CGSize)size forAttributedString:(NSAttributedString *)attributedString
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFMutableAttributedStringRef)attributedString);
    CFRange attributedStringRange = CFRangeMake(0, attributedString.length);
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, attributedStringRange, NULL, size, NULL);
    CFRelease(framesetter);
    
    return suggestedSize;
}



- (void)toggleRecordingWithCompletionHandler:(void (^)(BOOL isRunning, NSError *error))completionHandler
{
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    // Retrieve the video preview layer's video orientation on the main queue before entering the session queue. We do this to ensure UI
    // elements are accessed on the main thread and session configuration is done on the session queue.
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.cameraView.layer;
    AVCaptureVideoOrientation previewLayerVideoOrientation = previewLayer.connection.videoOrientation;
    dispatch_async( self.sessionQueue, ^{
        if ( ! self.movieFileOutput.isRecording ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                //[self.recordButton setImage:[[UIImage systemImageNamed:@"stop.circle"] imageWithTintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
                //[self.recordButton setTintColor:[UIColor whiteColor]];
            });
            if ( [UIDevice currentDevice].isMultitaskingSupported ) {
                // Setup background task. This is needed because the -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
                // callback is not received until AVCamManual returns to the foreground unless you request background execution time.
                // This also ensures that there will be time to write the file to the photo library when AVCamManual is backgrounded.
                // To conclude this background execution, -endBackgroundTask is called in
                // -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
                self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
            }
            AVCaptureConnection *movieConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            movieConnection.videoOrientation = previewLayerVideoOrientation;
            
            // Start recording to temporary file
            NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
            [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
            completionHandler(TRUE, nil);
        }
        else {
            [self.movieFileOutput stopRecording];
            dispatch_async( dispatch_get_main_queue(), ^{
                //[self.recordButton setImage:[[UIImage systemImageNamed:@"stop.circle"] imageWithTintColor:[UIColor redColor]] forState:UIControlStateNormal];
                //[self.recordButton setTintColor:[UIColor redColor]];
            });
            completionHandler(FALSE, nil);
        }
    } );
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    // Enable the Record button to let the user stop the recording
    dispatch_async( dispatch_get_main_queue(), ^{
        //[self.recordButton setImage:[[UIImage systemImageNamed:@"stop.circle.fill"] imageWithTintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        //[self.recordButton setTintColor:[UIColor whiteColor]];
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
        if ( [[NSFileManager defaultManager] fileExistsAtPath:outputFileURL.path] ) {
            [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        }
        
        if ( currentBackgroundRecordingID != UIBackgroundTaskInvalid ) {
            [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
        }
    };
    
    BOOL success = YES;
    
    if ( error ) {
        //NSLog( @"Error occurred while capturing movie: %@", error );
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    if ( success ) {
        // Check authorization status
        [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
            if ( status == PHAuthorizationStatusAuthorized ) {
                // Save the movie file to the photo library and cleanup
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    // In iOS 9 and later, it's possible to move the file into the photo library without duplicating the file data.
                    // This avoids using double the disk space during save, which can make a difference on devices with limited free disk space.
                    PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                    options.shouldMoveFile = YES;
                    PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
                    [changeRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
                } completionHandler:^( BOOL success, NSError *error ) {
                    if ( ! success ) {
                        //NSLog( @"Could not save movie to photo library: %@", error );
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
}

//- (void)handleTouchForButtonWithCameraProperty:(CameraProperty)cameraProperty
//{
//    CameraProperty selectedButtonCameraProperty = cameraPropertyForSelectedButtonInIBOutletCollection(self.cameraPropertyButtons);
//    BOOL cameraPropertiesIdentical = (cameraProperty == selectedButtonCameraProperty) ? TRUE : FALSE;
//    [self deselectCameraControlButtonForCameraProperty:selectedButtonCameraProperty];
//    [self selectCameraControlButtonForCameraProperty:(cameraPropertiesIdentical) ? nil : cameraProperty];
//
//}
//

- (IBAction)cameraPropertyButtonEventHandler:(UIButton *)sender forEvent:(UIEvent *)event
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    CameraProperty selectedButtonCameraProperty = ([sender isSelected]) ? (CameraProperty)[sender tag] : cameraPropertyForSelectedButtonInIBOutletCollection(self.cameraPropertyButtons);
    CameraProperty senderButtonCameraProperty = (CameraProperty)[sender tag];
    BOOL senderButtonCameraPropertyEqualsSelectedButtonCameraProperty = (senderButtonCameraProperty == selectedButtonCameraProperty) ? TRUE : FALSE;
    BOOL shouldSelectSender = (!senderButtonCameraPropertyEqualsSelectedButtonCameraProperty && (selectedButtonCameraProperty == CameraPropertyInvalid)) ? TRUE : FALSE;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lockedCameraPropertyButton = (shouldSelectSender) ? sender : nil; //requestButtonInIBOutletCollectionWithCameraProperty(self.cameraPropertyButtons, senderButtonCameraProperty) : nil;
        [sender setSelected:shouldSelectSender];
        [sender setHighlighted:shouldSelectSender];
        //            UIImage *symbol = [[(UIButton *)selectedButton currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleLargeTitle]];
        //            [(UIButton *)selectedButton setImage:symbol forState:UIControlStateNormal];
        [self.scaleSliderControlViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [(UIView *)obj setHidden:!shouldSelectSender];
            [(UIView *)obj setNeedsDisplay];
        }];
        [self.scaleSliderControlTextLayer setHidden:!shouldSelectSender];
        [self.scaleSliderControlTextLayer setNeedsLayout];
    });
    // if the sender is selected, deselect it and stop
    // if the sender is not selected, select it if there is no other button selected
    
    //        CameraProperty senderButtonCameraProperty = (CameraProperty)[sender tag];
    //        CameraProperty buttonCameraProperty = (CameraProperty)[button tag];
    //
    //        (isButtonSelected) ? (CameraProperty)[button tag] : (isSenderSelected) ? senderButtonCameraProperty : CameraPropertyInvalid;
    //
    //        BOOL shouldSelectSender = (!isSenderSelected) ? !isSenderSelected : TRUE;
    //
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //                [sender setSelected:shouldSelectSender];
    //                [sender setHighlighted:shouldSelectSender];
    //                //            UIImage *symbol = [[(UIButton *)selectedButton currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleLargeTitle]];
    //                //            [(UIButton *)selectedButton setImage:symbol forState:UIControlStateNormal];
    //                //                    [self.scaleSliderControlView setHidden:!senderCameraPropertyIsEqualToSelectedCameraProperty];
    //                //                    [self.scaleSliderOverlayView setNeedsDisplay];
    //            });
    //
    //    CameraProperty selectedButtonCameraProperty = cameraPropertyForSelectedButtonInIBOutletCollection(self.cameraPropertyButtons);
    //    CameraProperty senderButtonCameraProperty = (CameraProperty)[sender tag];
    //    BOOL senderCameraPropertyIsEqualToSelectedCameraProperty = (senderButtonCameraProperty == selectedButtonCameraProperty) ? TRUE : FALSE;
    //    if (senderCameraPropertyIsEqualToSelectedCameraProperty)
    //    {
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            [sender setSelected:!senderCameraPropertyIsEqualToSelectedCameraProperty];
    //            [sender setHighlighted:!senderCameraPropertyIsEqualToSelectedCameraProperty];
    //            //            UIImage *symbol = [[(UIButton *)selectedButton currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleLargeTitle]];
    //            //            [(UIButton *)selectedButton setImage:symbol forState:UIControlStateNormal];
    //            //                    [self.scaleSliderControlView setHidden:!senderCameraPropertyIsEqualToSelectedCameraProperty];
    //            //                    [self.scaleSliderOverlayView setNeedsDisplay];
    //        });
    //    }
    //
    //    //            [self selectCameraControlButtonForCameraProperty:(cameraPropertiesIdentical) ? nil : senderButtonCameraProperty];
    //    //            dispatch_async(dispatch_get_main_queue(), ^{
    //    //                // Hide the slider? TRUE if the sender button is selected || if the sender button is not selected && if the slider is showing (TRUE)
    //    //                [self.scaleSliderControlView setHidden:([(UIButton *)sender isSelected] && !(self.scaleSliderControlView.isHidden))]; // is the sender is not already selected (and, therefore, displaying the slider,
    //    //                [self.cameraPropertyButtons enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    //    //                    dispatch_async(dispatch_get_main_queue(), ^{
    //    //                        BOOL shouldSelect = ([sender isEqual:(UIButton *)obj]) ? TRUE : FALSE; // if the enumerated button and the sender button are the same AND the sender button is not already selected...
    //    //                        [(UIButton *)obj setSelected:shouldSelect];
    //    //                        [(UIButton *)obj setHighlighted:shouldSelect];
    //    //                        UIImage *symbol = (shouldSelect) ? [[(UIButton *)obj currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleTitle2 /* configurationWithScale:UIImageSymbolScaleSmall*/]] : [[(UIButton *)obj currentImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleLargeTitle]];
    //    //                        [(UIButton *)obj setImage:symbol forState:UIControlStateNormal];
    //    //                        if (shouldSelect)
    //    //                        {
    //    //                                                [self.scaleSliderControlView setHidden:(!shouldSelect)];
    //    //                            //                            [self.scaleSliderOverlayView setSelectedCameraPropertyValue:[self selectedCameraPropertyFrame]];
    //    //                                                        [self.scaleSliderOverlayView setNeedsDisplay];
    //    //
    //    //                            float value = cameraPropertyFunc(self.videoDevice, (CameraProperty)[(UIButton *)obj tag]);
    //    ////                            NSLog(@"Value for scroll view content offset in cameraControlAction BEFORE normalization: %f", value);
    //    //                            value = (value < 0.0) ? 0.0 : (value > 10.0) ? 10.0 : value;
    //    ////                            NSLog(@"Value for scroll view content offset in cameraControlAction AFTER NORMALIZATION,r: %f", value);
    //    //                            [self.scaleSliderScrollView setContentOffset:CGPointMake(-CGRectGetMidX(self.scaleSliderScrollView.frame) + (self.scaleSliderScrollView.contentSize.width * value), 0.0) animated:TRUE];//  scrollRectToVisible:scrollRect animated:FALSE];
    //    //                            //                            [self setMeasuringUnit:[[self cameraPropertyNumberFormatter] stringFromNumber:[NSNumber numberWithFloat:(value * 10)]]];
    //    //                            //                    //NSLog(@"origin x (1): %f", ((UIButton *)obj).frame.origin.x);
    //    //                        }
    //    //                    });
    //    //                }];
    //    //            });
    //    //    });
}

@end
