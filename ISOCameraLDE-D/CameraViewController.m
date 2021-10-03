//
//  CameraViewController.m
//  ISOCameraLDE
//
//  Created by Xcode Developer on 6/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

// TO-DO: Create an icon of the camera aperture that compounds the exposure duration and ISO settings
// into a singular visual representation. The major descriptive features will be the size
// of the aperture's opening and the duration of its opening:

// The aperture will open and close at a rate equivalent to the number of frames captured per second
// per the exposure duration setting;

// The difference between the border of the aperture and the size of the opening will approximate the ISO setting.

// Representing these two seemingly disparate settings by a single image informs their shared relationship with
// the camera aperture, and makes distinct their otherwise seemingly identical effect on image brightness.
// The icon underscores the relevance of the aperture configuration to the process for acquiring samples and emphasizes the importance of determining optimal
// configuration

// Pattern icons from these SF Symbols:
// circle
// circle.fill
// largecircle.fill.circle
// smallcircle.fill.circle
// smallcircle.fill.circle.fill
// smallcircle.circle
// smallcircle.circle.fill

// TO-DO: Use the circle and viewfinder SF Symbols as the image and background image (respectively) as the lens position camera property button icon.
// Adjust the size of the viewfinder image per the lens position.

@import AVFoundation;
@import Photos;
@import CoreText;

#import "CameraViewController.h"
#import "CameraView.h"

typedef NS_ENUM(NSInteger, AVCamManualSetupResult) {
    AVCamManualSetupResultSuccess,
    AVCamManualSetupResultCameraNotAuthorized,
    AVCamManualSetupResultSessionConfigurationFailed
};

// TO-DO:
// 1. Adjust white balance when torch is toggled
// 2. Add a key-value observer for changes to torch
// 3. Set to highest camera resolution available

@interface CameraViewController () <AVCaptureFileOutputRecordingDelegate>

@property (weak, nonatomic) IBOutlet CameraView *cameraView;


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
    
    [self.buttonCollectionView setButtonCollectionViewDelegate:(id<ButtonCollectionViewDelegate> _Nullable)self];
    
    //    CGFloat frameMinX  =    -(CGRectGetMidX(self.scaleSliderScrollView.frame));
    //    CGFloat frameMaxX  =      CGRectGetMaxX(self.scaleSliderScrollView.frame) + fabs(CGRectGetMidX(self.scaleSliderScrollView.frame));
    //    CGFloat insetMin   = fabs(CGRectGetMidX(self.scaleSliderScrollView.frame) - CGRectGetMinX(self.scaleSliderScrollView.frame));
    //    CGFloat insetMax   =     (CGRectGetMaxX(self.scaleSliderScrollView.frame) - CGRectGetMidX(self.scaleSliderScrollView.frame)) * 0.5;
    //    [self.scaleSliderScrollView setContentInset:UIEdgeInsetsMake(CGRectGetMinY(self.scaleSliderScrollView.frame), insetMin, CGRectGetMaxY(self.scaleSliderScrollView.frame), insetMin)];
    //    //    [self.scaleSliderScrollView setFrame:self.cameraControls.frame];
}

typedef void (^CameraPropertyCallback)(CameraProperty selectedButtonCameraProperty);

static void (^cameraPropertyForSelectedButtonInIBOutletCollection)(NSArray *, CameraPropertyCallback) = ^ (NSArray * cameraPropertyButtons, CameraPropertyCallback callback)
{
    [cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton *  _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isSelected = [button isSelected];
        CameraProperty cameraProperty = (isSelected && [button tag] != CameraPropertyRecord) ? [button tag] : CameraPropertyInvalid;
        callback(cameraProperty);
        *stop = isSelected;
    }];
};

//static UIButton * (^selectedButtonInIBOutletCollection)(NSArray *) = ^ UIButton *(NSArray * cameraPropertyButtons)
//{
//    __block UIButton * selectedButton = nil;
//    [cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton *  _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
//        BOOL isSelected = [button isSelected];
//        if (isSelected) selectedButton = button;
//        *stop = isSelected;
//    }];
//
//    return (selectedButton.tag != CameraPropertyRecord) ? selectedButton : nil;
//};

- (UIButton *)buttonWithTag:(NSUInteger)tag
{
    __block UIButton * requestedButton = nil;
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *  _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL cameraPropertiesMatch = ((CameraProperty)[button tag] == tag) ? TRUE : FALSE;
        if (cameraPropertiesMatch) requestedButton = button;
        *stop = cameraPropertiesMatch;
    }];
    
    return requestedButton;
};

//- (void)connectTouchUpInsideEventHandlerToCameraPropertyButtons:(NSArray <UIButton *> *)buttons
//{
//    [buttons enumerateObjectsUsingBlock:^(UIButton *  _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
//        [button targetForAction:@selector(cameraPropertyButtonEventHandler:forEvent:) withSender:button];
//    }];
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //    [self.cameraControlsContainerView setDelegate:(id<CameraControlsDelegate> _Nullable)self];
    
    [self.buttons makeObjectsPerformSelector:@selector(setReversesTitleShadowWhenHighlighted:) withObject:@(FALSE)];
//    UIEdgeInsets contentInsets = UIEdgeInsetsMake(15, 5, 5, 5);
//    NSValue *contentInsetsValue = [NSValue valueWithUIEdgeInsets:contentInsets];
//    [self.buttons makeObjectsPerformSelector:@selector(setContentEdgeInsets:) withObject:contentInsetsValue];
//    [self.buttons makeObjectsPerformSelector:@selector(setContentVerticalAlignment:) withObject:@(UIControlContentVerticalAlignmentBottom)];
    // Create the AVCaptureSession
    self.session = [[AVCaptureSession alloc] init];
    
    // Create a device discovery session
    NSArray<NSString *> *deviceTypes = @[AVCaptureDeviceTypeBuiltInDualCamera];
    self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    
    // Set up the preview view
    self.cameraView.session = self.session;
    
    // Communicate with the session and other session objects on this queue
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    self.setupResult = AVCamManualSetupResultSuccess;
    
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
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
            dispatch_suspend(self.sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (! granted) {
                    self.setupResult = AVCamManualSetupResultCameraNotAuthorized;
                }
                dispatch_resume(self.sessionQueue);
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
    dispatch_async(self.sessionQueue, ^{
        [self configureSession];
    });
}

- (void)configureSession
{
    if (self.setupResult != AVCamManualSetupResultSuccess) {
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
            if (connection.isVideoStabilizationSupported) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            self.movieFileOutput = movieFileOutput;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
            if (statusBarOrientation != UIInterfaceOrientationUnknown) {
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
    
    dispatch_async(self.sessionQueue, ^{
        switch (self.setupResult)
        {
            case AVCamManualSetupResultSuccess:
            {
                //                [self addObservers];
                [self.session startRunning];
                //                self.sessionRunning = self.session.isRunning;
                if (self.session.isRunning)
                {
                    __autoreleasing NSError *error = nil;
                    @try {
                        if ([self.videoDevice lockForConfiguration:&error])
                        {
                            NSLog(@"Configuring camera for highest frame rate...");
                            [self configureCameraForHighestFrameRateWithCompletionHandler:^(NSString *error_description) {
                                if (error_description)
                                {
                                    NSLog(@"Error configuring camera for highest frame rate: %@", error_description);
                                } else {
                                    NSLog(@"Configured camera for highest frame rate.");
                                    NSLog(@"Enabling auto-exposure...");
                                    [self autoExposureWithCompletionHandler:^(NSString *error_description) {
                                        if (error_description)
                                        {
                                            NSLog(@"Error setting auto-exposure: %@", error_description);
                                        } else {
                                            NSLog(@"Auto-exposure enabled.");
                                            NSLog(@"Enabling auto-focus...");
                                            [self autoFocusWithCompletionHandler:^(NSString *error_description) {
                                                if (error_description)
                                                {
                                                    NSLog(@"Error setting auto-exposure: %@", error_description);
                                                } else {
                                                    NSLog(@"Auto-focus enabled.");
                                                }
                                            }];
                                        }
                                    }];
                                }
                            }];
                        }
                    } @catch (NSException *exception) {
                        NSLog(@"\n\n%@\n%@\n\n", error.description, exception.description);
                    } @finally {
                        [self lockDevice];
                    }
                }
                break;
            }
            case AVCamManualSetupResultCameraNotAuthorized:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString(@"AVCamManual doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera");
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCamManual" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert OK button") style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", @"Alert button to open Settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
            case AVCamManualSetupResultSessionConfigurationFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString(@"Unable to capture media", @"Alert message when something goes wrong during capture session configuration");
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCamManual" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert OK button") style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
        }
    });
}

#pragma mark Device configuration

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

- (void)lockDevice
{
    //    NSLog(@"%s", __PRETTY_FUNCTION__);
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
            //NSLog(@"Could not lock device for configuration: %@\t%@", exception.description, error.description);
        } @finally {
            
        }
    });
}

- (void)configureCameraForHighestFrameRateWithCompletionHandler:(void (^)(NSString *error_description))completionHandler
{
    __block NSString *error = nil;
    @try {
        AVCaptureDeviceFormat *bestFormat = nil;
        AVFrameRateRange *bestFrameRateRange = nil;
        for (AVCaptureDeviceFormat *format in [self.videoDevice formats]) {
            for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                if (range.maxFrameRate > bestFrameRateRange.maxFrameRate) {
                    bestFormat = format;
                    bestFrameRateRange = range;
                }
            }
        }
        if (bestFormat) {
            self.videoDevice.activeFormat = bestFormat;
            self.videoDevice.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
            self.videoDevice.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
        } else {
            error = @"Unable to configure camera for highest frame rate.";
        }
    } @catch (NSException *exception) {
        error = exception.description;
    } @finally {
        completionHandler(error);
    }
}

- (void)autoExposureWithCompletionHandler:(void (^)(NSString *error_description))completionHandler
{
    __block NSString *error = nil;
    @try {
        [self.videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    } @catch (NSException *exception) {
        error = exception.description;
    } @finally {
        completionHandler(error);
    }
}

- (void)autoFocusWithCompletionHandler:(void (^)(NSString *error_description))completionHandler
{
    __block NSString *error = nil;
    @try {
        [self.videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    } @catch (NSException *exception) {
        error = exception.description;
    } @finally {
        completionHandler(error);
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async(self.sessionQueue, ^{
        if (self.setupResult == AVCamManualSetupResultSuccess) {
            [self.session stopRunning];
            //            [self removeObservers];
        }
    });
    
    [super viewDidDisappear:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation)) {
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
    return FALSE;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
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
    dispatch_async(dispatch_get_main_queue(), ^{
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
            //            [button setTitle:[NSString stringWithFormat:@"%.1f", newFloatValue] forState:UIControlStateNormal];
            //            [button setTintColor:[UIColor systemBlueColor]];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [button setTintColor:[UIColor systemBlueColor]];
    });
    
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
//                            CMTime newExposureDuration = CMTimeMakeWithSeconds(exposureDuration, currentExposureDurationTimeScale);
//                            [self.videoDevice setExposureModeCustomWithDuration:newExposureDuration ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
//                                self_block(@"videoDevice.exposureDuration");
//                            }];
//                        }
//                    }
//                } @catch (NSException *exception) {
//                    //NSLog(@"Error configuring device:\t%@", exception.description);
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
//    //                        CMTime newExposureDuration = CMTimeMakeWithSeconds(exposureDuration, currentExposureDurationTimeScale);
//    //                        [self.videoDevice setExposureModeCustomWithDuration:newExposureDuration ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
//    //                            [self didChangeValueForKey:@"videoDevice.exposureDuration"];
//    //                        }];
//    //                    }
//    //                }
//    //            } @catch (NSException *exception) {
//    //                //NSLog(@"Error configuring device:\t%@", exception.description);
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
//                if (property == CameraPropertyLensPosition) {
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
//                        CMTime newExposureDuration = CMTimeMakeWithSeconds(exposureDuration, currentExposureDurationTimeScale);
//                        [self.videoDevice setExposureModeCustomWithDuration:newExposureDuration ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
//                            [self didChangeValueForKey:@"videoDevice.exposureDuration"];
//                        }];
//                    }
//                }
//            } @catch (NSException *exception) {
//                //NSLog(@"Error configuring device:\t%@", exception.description);
//            } @finally {
//
//            }
//        }); dispatch_semaphore_signal([self device_lock_semaphore]);
//    };
//}

//- (IBAction)handleTapGesture:(UITapGestureRecognizer *)sender {
//    [self.buttons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        CGRect convertedRect = [obj convertRect:[obj frame] toView:self.scaleSliderScrollView];\
//        BOOL isPointInsideButtonRect = CGRectContainsPoint(convertedRect, [sender locationInView:self.scaleSliderScrollView]);
//
//        if (isPointInsideButtonRect)
//        {
//            NSLog(@"Camera property %lu", (CameraProperty)obj.tag);
//            NSLog(@"convertedRect: %f, %f, %f, %f", convertedRect.origin.x, convertedRect.origin.y, convertedRect.size.width, convertedRect.size.height);
//            NSLog(@"[sender locationInView:self.scaleSliderScrollView] %f, %f", [sender locationInView:self.scaleSliderScrollView].x, [sender locationInView:self.scaleSliderScrollView].y);
//
//            if (((UIButton *)obj).tag == CameraPropertyRecord)
//            {
//                NSLog(@"RECORD");
//                [self toggleRecording:obj];
//            } else {
//                NSLog(@"%lu", idx);
//                [self cameraPropertyButtonEventHandler:(UIButton *)obj];
//            }
//        } else {
////            NSLog(@"No");
//        }
//        *stop = isPointInsideButtonRect;
//    }];
//}

- (void)displayValuesForCameraControlProperties
{
    [self.cameraPropertyButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            double value = cameraPropertyFunc(self.videoDevice, (CameraProperty)[obj tag]);
            NSString *title = [[self cameraPropertyNumberFormatter] stringFromNumber:[NSNumber numberWithFloat:value]];
            //            [obj setTitle:title forState:UIControlStateNormal];
            //            [obj setTintColor:[UIColor systemBlueColor]];
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
    dispatch_queue_t dispatch_queue = _textureQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_REPLACE, 0, 0, dispatch_queue);
        dispatch_source_set_event_handler(dispatch_source, ^{
            dispatch_async([self device_configuration_queue], ^{
                dispatch_semaphore_wait([self device_lock_semaphore], DISPATCH_TIME_FOREVER);
                dispatch_async(dispatch_get_main_queue(), ^{
                    float value = (float)dispatch_source_get_data(dispatch_source);
                    //                    NSLog(@"value: %f", value);
                    CameraProperty property = (CameraProperty)self.lockedCameraPropertyButton.tag;
                    @try {
                        if (property == CameraPropertyLensPosition && [self.videoDevice isFocusModeSupported:AVCaptureFocusModeLocked])
                        {
                            [self willChangeValueForKey:@"videoDevice.lensPosition"];
                            if (![self.videoDevice isAdjustingFocus])
                                [self.videoDevice setFocusModeLockedWithLensPosition:value completionHandler:^(CMTime syncTime) {
                                    [self didChangeValueForKey:@"videoDevice.lensPosition"];
                                }];
                        } else if (property == CameraPropertyISO) {
                            //                        if (![self.videoDevice isAdjustingExposure]) {
                            //                            [self willChangeValueForKey:@"self.ISO"];
                            //                            float maxISO = self.videoDevice.activeFormat.maxISO;
                            //                            float minISO = self.videoDevice.activeFormat.minISO;
                            //                            float ISO = minISO + (value * (maxISO - minISO));
                            //                            ISO = ((ISO > minISO) && (ISO < maxISO)) ? ISO : self.videoDevice.ISO;
                            //                            [self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:ISO completionHandler:^(CMTime syncTime) {
                            //                                [self didChangeValueForKey:@"self.ISO"];
                            //                            }];
                            //                        }
                        } else if (property == CameraPropertyTorchLevel && ([[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateCritical && [[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateSerious)) {
                            [self willChangeValueForKey:@"videoDevice.torchLevel"];
                            if (value == 0.0)
                                [self->_videoDevice setTorchMode:AVCaptureTorchModeOff];
                            else
                                [self->_videoDevice setTorchModeOnWithLevel:value error:nil];
                            [self didChangeValueForKey:@"videoDevice.torchLevel"];
                        } else if (property == CameraPropertyVideoZoomFactor) {
                            if (![self.videoDevice isRampingVideoZoom]) {
                                [self willChangeValueForKey:@"videoZoomFactor"];
                                float maxZoom = self.videoDevice.maxAvailableVideoZoomFactor;
                                float minZoom = self.videoDevice.minAvailableVideoZoomFactor;
                                float zoomValue = minZoom + (pow(value, 5.0) * (maxZoom - minZoom));
                                zoomValue = (zoomValue < minZoom) ? minZoom : (zoomValue > maxZoom) ? maxZoom : zoomValue;
                                //                        zoomValue = 1.0 + (zoomValue * (self.videoDevice.activeFormat.videoMaxZoomFactor - 1.0));
                                [self.videoDevice setVideoZoomFactor:zoomValue];
                                [self didChangeValueForKey:@"videoZoomFactor"];
                            }
                        } else if (property == CameraPropertyExposureDuration) {
                            //                        if (![self.videoDevice isAdjustingExposure]) {
                            //                            [self willChangeValueForKey:@"videoDevice.exposureDuration"];
                            //                            double minDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration);
                            //                            double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
                            //                            // Map from duration to non-linear UI range 0-1
                            //                            float exposureDuration = minDurationSeconds + (value * (maxDurationSeconds - minDurationSeconds));
                            //                            //                    //NSLog(@"Exposure duration factor (%lu) value: %f", property, value);
                            //                            double currentExposureDurationTimeScale = self.videoDevice.exposureDuration.timescale;
                            //                            CMTime newExposureDuration = CMTimeMakeWithSeconds(exposureDuration, currentExposureDurationTimeScale);
                            //                            [self.videoDevice setExposureModeCustomWithDuration:newExposureDuration ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
                            //                                self_block(@"videoDevice.exposureDuration");
                            //                            }];
                            //                        }
                        }
                    } @catch (NSException *exception) {
                        //NSLog(@"Error configuring device:\t%@", exception.description);
                    } @finally {
                        
                    }
                });
            });
            dispatch_semaphore_signal([self device_lock_semaphore]);
        });
        dispatch_set_target_queue(dispatch_source, dispatch_queue);
        dispatch_resume(dispatch_source);
        self->_textureQueueEvent = dispatch_source;
    });
    
    return dispatch_source;
}

void (^changedValueForKey)(__weak __typeof__ (CameraViewController *), NSString *) = ^void (__weak __typeof__ (CameraViewController *) w_self, NSString *key) {
    __typeof__(CameraViewController *) s_self = w_self;
    [s_self didChangeValueForKey:key];
};

// Set the value of the specified camera property to the value of the scrollview x position
// Returns the equivalent value for the property specified for display by the scrollview
typedef float(^configureProperty)(CameraProperty, float);

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    __weak __typeof__(CameraViewController *) weakSelf = (CameraViewController *)self;
    dispatch_async([self device_configuration_queue], ^{
        dispatch_semaphore_wait([self device_lock_semaphore], DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            float value = ((ScaleSliderScrollView *)scrollView).value.floatValue;
            //            NSLog(@"value %f", value);
            CameraProperty property = (CameraProperty)self.lockedCameraPropertyButton.tag;
            @try {
                if (property == CameraPropertyLensPosition && [self.videoDevice isFocusModeSupported:AVCaptureFocusModeLocked])
                {
                    [self willChangeValueForKey:@"videoDevice.lensPosition"];
                    if (![self.videoDevice isAdjustingFocus] && (value != self.videoDevice.lensPosition))
                        [self.videoDevice setFocusModeLockedWithLensPosition:value completionHandler:^(CMTime syncTime) {
                            changedValueForKey(weakSelf, @"videoDevice.lensPosition");
                            UIButton *lensPositionCameraPropertyButton = [self buttonWithTag:CameraPropertyLensPosition];
                            UIImage *symbol = [[lensPositionCameraPropertyButton currentBackgroundImage] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:value weight:UIImageSymbolWeightUltraLight scale:UIImageSymbolScaleSmall]];
                            [lensPositionCameraPropertyButton setBackgroundImage:symbol forState:UIControlStateNormal];
                        }];
                } else if (property == CameraPropertyISO) {
                    if (value != (double)CMTimeGetSeconds(self.videoDevice.exposureDuration)) {
                        //                    if (![self.videoDevice isAdjustingExposure]) {
                        [self willChangeValueForKey:@"self.ISO"];
                        float maxISO = self.videoDevice.activeFormat.maxISO;
                        float minISO = self.videoDevice.activeFormat.minISO;
                        float ISO = minISO + (value * (maxISO - minISO));
                        ISO = ((ISO > minISO) && (ISO < maxISO)) ? ISO : self.videoDevice.ISO;
                        [self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:value completionHandler:^(CMTime syncTime) {
                            changedValueForKey(weakSelf, @"self.ISO");
                        }];
                    }
                } else if (property == CameraPropertyTorchLevel && ([[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateCritical && [[NSProcessInfo processInfo] thermalState] != NSProcessInfoThermalStateSerious)) {
                    [self willChangeValueForKey:@"videoDevice.torchLevel"];
                    if (value == 0.0)
                        [self->_videoDevice setTorchMode:AVCaptureTorchModeOff];
                    else
                        [self->_videoDevice setTorchModeOnWithLevel:value error:nil];
                    changedValueForKey(weakSelf, @"videoDevice.torchLevel");
                } else if (property == CameraPropertyVideoZoomFactor) {
                    if (![self.videoDevice isRampingVideoZoom]) {
                        [self willChangeValueForKey:@"videoZoomFactor"];
                        [self.videoDevice setVideoZoomFactor:value];
                        changedValueForKey(weakSelf, @"videoZoomFactor");
                    }
                } else if (property == CameraPropertyExposureDuration) {
                    if (![self.videoDevice isAdjustingExposure]) {
                        [self willChangeValueForKey:@"videoDevice.exposureDuration"];
                        //                        double minDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration);
                        //                        double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
                        //                        // Map from duration to non-linear UI range 0-1
                        //                        float exposureDuration = minDurationSeconds + (value * (maxDurationSeconds - minDurationSeconds));
                        //                        //                    //NSLog(@"Exposure duration factor (%lu) value: %f", property, value);
                        double currentExposureDurationTimeScale = self.videoDevice.exposureDuration.timescale;
                        CMTime newExposureDuration = CMTimeMakeWithSeconds(value, currentExposureDurationTimeScale);
                        [self.videoDevice setExposureModeCustomWithDuration:newExposureDuration ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
                            changedValueForKey(weakSelf, @"videoDevice.exposureDuration");
                        }];
                    }
                }
            } @catch (NSException *exception) {
                //NSLog(@"Error configuring device:\t%@", exception.description);
            } @finally {
                [scrollView setValue:@(value)];
            }
        });
    });
    dispatch_semaphore_signal([self device_lock_semaphore]);
    // dispatch_source_merge_data([self textureQueueEvent], value);
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        [self.lockedCameraPropertyButton setTitle:[NSString stringWithFormat:@"%lu", value] forState:UIControlStateNormal];
    //    });
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
            cameraPropertyValue = (double)CMTimeGetSeconds(videoDevice.exposureDuration); //videoDevice.exposureDuration.timescale / (double)videoDevice.exposureDuration.value;
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
            cameraPropertyValue = 0.0;
            break;
        }
    }
    
    return cameraPropertyValue;
}

- (IBAction)toggleRecording:(UIButton *)sender {
    [self toggleRecordingWithCompletionHandler:^(BOOL isRecording, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender setSelected:isRecording];
            [sender setHighlighted:isRecording];
        });
    }];
}

- (IBAction)toggleExposureDuration:(UIButton *)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        __autoreleasing NSError *error = nil;
        @try {
            if ([self.videoDevice lockForConfiguration:&error])
            {
                NSLog(@"Configuring camera for highest frame rate...");
                [self configureCameraForHighestFrameRateWithCompletionHandler:^(NSString *error_description) {
                    if (error_description)
                    {
                        NSLog(@"Error configuring camera for highest frame rate: %@", error_description);
                    } else {
                        NSLog(@"Configured camera for highest frame rate.");
                        if ([sender isSelected])
                        {
                            NSLog(@"Enabling auto-exposure...");
                            [self autoExposureWithCompletionHandler:^(NSString *error_description) {
                                if (error_description)
                                {
                                    NSLog(@"Error setting auto-exposure: %@", error_description);
                                } else {
                                    NSLog(@"Auto-exposure enabled.");
                                    NSLog(@"Enabling auto-focus...");
                                    [self autoFocusWithCompletionHandler:^(NSString *error_description) {
                                        if (error_description)
                                        {
                                            NSLog(@"Error setting auto-exposure: %@", error_description);
                                        } else {
                                            NSLog(@"Auto-focus enabled.");
                                        }
                                    }];
                                }
                            }];
                            [sender setSelected:FALSE];
                            [sender setHighlighted:FALSE];
                        } else {
                            
                            [sender setSelected:TRUE];
                            [sender setHighlighted:TRUE];
                        }
                    }
                }];
            }
        } @catch (NSException *exception) {
            NSLog(@"\n\n%@\n%@\n\n", error.description, exception.description);
        } @finally {
            [self.videoDevice unlockForConfiguration];
            
        }
    });
}

- (void)toggleRecordingWithCompletionHandler:(void (^)(BOOL isRecording, NSError *error))completionHandler
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.cameraView.layer;
    AVCaptureVideoOrientation previewLayerVideoOrientation = previewLayer.connection.videoOrientation;
    dispatch_async(self.sessionQueue, ^{
        if (! self.movieFileOutput.isRecording) {
            //            dispatch_async(dispatch_get_main_queue(), ^{
            //                //[self.recordButton setImage:[[UIImage systemImageNamed:@"stop.circle"] imageWithTintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
            //                //[self.recordButton setTintColor:[UIColor whiteColor]];
            //            });
            if ([UIDevice currentDevice].isMultitaskingSupported) {
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
            //            dispatch_async(dispatch_get_main_queue(), ^{
            //                //[self.recordButton setImage:[[UIImage systemImageNamed:@"stop.circle"] imageWithTintColor:[UIColor redColor]] forState:UIControlStateNormal];
            //                //[self.recordButton setTintColor:[UIColor redColor]];
            //            });
            completionHandler(FALSE, nil);
        }
    });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    //    // Enable the Record button to let the user stop the recording
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        //[self.recordButton setImage:[[UIImage systemImageNamed:@"stop.circle.fill"] imageWithTintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    //        //[self.recordButton setTintColor:[UIColor whiteColor]];
    //    });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
    dispatch_block_t cleanup = ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:outputFileURL.path]) {
            [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        }
        
        if (currentBackgroundRecordingID != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
        }
    };
    
    BOOL success = YES;
    
    if (error) {
        //NSLog(@"Error occurred while capturing movie: %@", error);
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    if (success) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                    options.shouldMoveFile = YES;
                    PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
                    [changeRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
                } completionHandler:^(BOOL success, NSError *error) {
                    //                    if (! success) {
                    //                        //NSLog(@"Could not save movie to photo library: %@", error);
                    //                    }
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

static double (^percentageInRange)(double, double, double) = ^double(double value, double minimumValue, double maximumValue) {
    float value_perc = ((value - minimumValue) * 100.0) / (maximumValue - minimumValue);
    
    return value_perc;
};

- (IBAction)cameraPropertyButtonEventHandler:(UIButton *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        cameraPropertyForSelectedButtonInIBOutletCollection(self.cameraPropertyButtons, ^(CameraProperty selectedButtonCameraProperty) {
            BOOL hideScaleSlider = (selectedButtonCameraProperty != CameraPropertyInvalid) ? (selectedButtonCameraProperty != (CameraProperty)sender.tag) ? self.scaleSliderScrollView.hidden : FALSE : TRUE;
            [self.scaleSliderControlViews enumerateObjectsUsingBlock:^(typeof(UIView *)  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [(UIView *)obj setHidden:hideScaleSlider];
                [(UIView *)obj setNeedsDisplay];
            }];
            
            [sender setHighlighted:hideScaleSlider];
            [sender setSelected:hideScaleSlider];
            
            self.lockedCameraPropertyButton = (hideScaleSlider) ? nil : sender;
        
                if (!self.scaleSliderScrollView.isHidden)
                {
                    // Create a UIButton category that contains the min and max value ranges properties to eliminate look-up; configure once on launch (not every time a button is touched)
                    // the scroll view can get the values from the lockedCameraPropertyButton property at the time the lockedCameraPropertyButton is set
                    // Also, add a value property that is set by observing changes to another property (or that is an accessor method or block to the value of another property)
                    // (the min and max values should actually be an accessor method or block to the value of its associated property's min and max properties (just like specifying a data source)
                    NSArray<NSNumber *> * minMaxValues = [self cameraPropertyValueRange:(CameraProperty)sender.tag videoDevice:self.videoDevice];
                    [self.scaleSliderScrollView setMinimumValue:minMaxValues.firstObject];
                    [self.scaleSliderScrollView setMaximumValue:[NSNumber numberWithDouble:minMaxValues.firstObject.doubleValue + minMaxValues.lastObject.doubleValue]];
                    [self.scaleSliderScrollView setValue:[NSNumber numberWithDouble:cameraPropertyFunc(self.videoDevice, (CameraProperty)sender.tag)]];
                    // TO-DO:
                    // 1. Normalize (0%-100%) value using camera property minimum and maximum
                    float value_perc = percentageInRange(cameraPropertyFunc(self.videoDevice, (CameraProperty)sender.tag), minMaxValues.firstObject.doubleValue, minMaxValues.lastObject.doubleValue);
                    NSLog(@"value_perc %f", value_perc);
                    // 2. Multiply by content size width
                    CGFloat midWidth = fabs(CGRectGetMidX(self.scaleSliderScrollView.frame) - CGRectGetMinX(self.scaleSliderScrollView.frame));
                    float contentOffsetX = (CGRectGetMaxX(self.scaleSliderScrollView.frame)) - midWidth;
                    
                    
                    // 3. Add product to -207 (use left-right inset to generate)
                    contentOffsetX = contentOffsetX  * (value_perc * .01);
                    // 4. Set content offset x to sum
                    NSLog(@"contentOffsetX %f", contentOffsetX);
                    [self.scaleSliderScrollView setContentOffset:CGPointMake(contentOffsetX, self.scaleSliderScrollView.frame.origin.y) animated:FALSE];
                    NSLog(@"contentOffsetX (actual) %f", self.scaleSliderScrollView.contentOffset.x);
                    // 621 > ContentOffset.x > -207
                }
        });
    });
}

- (NSArray<NSNumber *> *)cameraPropertyValueRange:(CameraProperty)cameraProperty videoDevice:(AVCaptureDevice *)videoDevice
{
    NSArray<NSNumber *> * propertyValueRange;
    switch (cameraProperty) {
        case CameraPropertyExposureDuration:
        {
            //            NSLog(@"%f %f", CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), CMTimeGetSeconds(videoDevice.activeFormat.maxExposureDuration));
            propertyValueRange = @[@(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration)), @(CMTimeGetSeconds(videoDevice.activeFormat.maxExposureDuration))];
            break;
        }
        case CameraPropertyISO:
        {
            propertyValueRange = @[@(videoDevice.activeFormat.minISO), @(videoDevice.activeFormat.maxISO)]; //NSMakeRange(videoDevice.activeFormat.minISO, videoDevice.activeFormat.maxISO);
            break;
        }
        case CameraPropertyLensPosition:
        {
            propertyValueRange = @[@(0.0), @(1.0)];
            break;
        }
        case CameraPropertyTorchLevel:
        {
            propertyValueRange = @[@(0.0), @(1.0)];
            break;
        }
        case CameraPropertyVideoZoomFactor:
        {
            propertyValueRange = @[@(self.videoDevice.minAvailableVideoZoomFactor), @(self.videoDevice.maxAvailableVideoZoomFactor)];
            break;
        }
            
        default:
        {
            propertyValueRange = @[@(0.0), @(1.0)];
        }
    }
    
    return propertyValueRange;
}

- (void)setLockedCameraButton:(UIButton *)lockedCameraButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
//        [lockedCameraButton setTitle:[NSString stringWithFormat:@"%.1f", lockedCameraButton.value.doubleValue] forState:UIControlStateNormal];
        self->_lockedCameraButton = lockedCameraButton;
    });
}

@end
