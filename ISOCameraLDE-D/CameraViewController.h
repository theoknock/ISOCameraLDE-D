//
//  CameraViewController.h
//  ISOCameraLDE
//
//  Created by Xcode Developer on 6/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import "CameraControls.h"
#import "ScaleSliderControlView.h"
#import "ScaleSliderScrollView.h"
#import "ScaleSliderView.h"
#import "ScaleSliderOverlayView.h"


NS_ASSUME_NONNULL_BEGIN

@interface CameraViewController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet CameraControls *cameraControls;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *cameraPropertyButtons;
@property (weak, nonatomic) IBOutlet ScaleSliderControlView *scaleSliderControlView;
@property (weak, nonatomic) IBOutlet ScaleSliderScrollView *scaleSliderScrollView;
@property (weak, nonatomic) IBOutlet ScaleSliderView *scaleSliderView;
@property (weak, nonatomic) IBOutlet ScaleSliderOverlayView *scaleSliderOverlayView;

@property (strong, nonatomic) __block AVCaptureDevice *videoDevice;

@property (nonatomic, getter=videoZoomFactor, setter=setVideoZoomFactor:) float videoZoomFactor;
@property (nonatomic, getter=ISO, setter=setISO:) float ISO;
@property (nonatomic, getter=isRecording, setter=setIsRecording:) BOOL isRecording;

- (void)autoExposureWithCompletionHandler:(void (^)(double ISO))completionHandler;

- (void)autoFocusWithCompletionHandler:(void (^)(double focus))completionHandler;

- (void)toggleRecordingWithCompletionHandler:(void (^)(BOOL isRunning, NSError *error))completionHandler;
- (void)setTorchLevel:(float)torchLevel;

- (void)scrollSliderControlToItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)lockDevice;
//- (SetCameraPropertyValueBlock)setCameraProperty:(CameraProperty)cameraProperty;
//- (float)valueForCameraProperty:(CameraProperty)cameraProperty;

@end

NS_ASSUME_NONNULL_END
