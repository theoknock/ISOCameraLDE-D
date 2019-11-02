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
#import "ButtonCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    CameraPropertyInvalid,
    CameraPropertyPosition,
    CameraPropertyRecord,
    CameraPropertyExposureDuration,
    CameraPropertyISO,
    CameraPropertyLensPosition,
    CameraPropertyTorchLevel,
    CameraPropertyVideoZoomFactor,
} CameraProperty;

@interface CameraViewController : UIViewController <ButtonCollectionViewDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *cameraPropertyButtons;
@property (weak, nonatomic) IBOutlet CameraControls *cameraControls;
@property (weak, nonatomic) IBOutlet ScaleSliderControlView *scaleSliderControlView;
@property (weak, nonatomic) IBOutlet ScaleSliderScrollView *scaleSliderScrollView;

@property (strong, nonatomic) __block AVCaptureDevice *videoDevice;

@property (nonatomic, getter=videoZoomFactor, setter=setVideoZoomFactor:) float videoZoomFactor;
@property (nonatomic, getter=ISO, setter=setISO:) float ISO;
@property (nonatomic, getter=isRecording, setter=setIsRecording:) BOOL isRecording;

- (void)autoExposureWithCompletionHandler:(void (^)(NSString *error_description))completionHandler;

- (void)autoFocusWithCompletionHandler:(void (^)(NSString *error_description))completionHandler;

- (void)toggleRecordingWithCompletionHandler:(void (^)(BOOL isRecording, NSError *error))completionHandler;
- (void)setTorchLevel:(float)torchLevel;

- (void)scrollSliderControlToItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)lockDevice;
//- (SetCameraPropertyValueBlock)setCameraProperty:(CameraProperty)cameraProperty;
//- (float)valueForCameraProperty:(CameraProperty)cameraProperty;

@property (strong, nonatomic) __block dispatch_source_t set_camera_property_event;
@property (weak, nonatomic) IBOutlet UIButton *recordCameraPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *exposureDurationCameraPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *ISOCameraPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *lensPositionCameraPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *torchLevelCameraPropertyButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomFactorCameraPropertyButton;

@property (strong, nonatomic) UIButton * _Nullable lockedCameraPropertyButton;
@property (strong, nonatomic) dispatch_queue_t button_setting_queue;
@property (strong, nonatomic) dispatch_semaphore_t button_lock_semaphore;

@property (nonatomic, strong) __block dispatch_queue_t dispatch_source_queue_value_getter;
@property (nonatomic, strong) __block dispatch_source_t dispatch_source_value_getter;

@property (strong, nonatomic) dispatch_queue_t textureQueue;
@property (strong, nonatomic) __block dispatch_source_t textureQueueEvent;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *scaleSliderControlViews;
@property (strong, nonatomic, setter=setLockedCameraButton:) UIButton * lockedCameraButton;

@property (weak, nonatomic) IBOutlet ButtonCollectionView *buttonCollectionView;
- (UIButton *)buttonWithTag:(NSUInteger)tag;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;


@end

NS_ASSUME_NONNULL_END
