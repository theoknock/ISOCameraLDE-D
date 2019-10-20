//
//  ScaleSliderControlView.h
//  ISOCameraLDE
//
//  Created by Xcode Developer on 10/3/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

@import UIKit;

#import "CameraPropertyDispatchSource.h"

@protocol ScaleSliderControlViewDelegate <NSObject>

- (void)handleTouchForButtonWithCameraProperty:(CameraProperty)cameraProperty;

@end

@interface ScaleSliderControlView : UIView <UIGestureRecognizerDelegate>

@property (weak, nonatomic, setter=setDelegate:, getter=delegate) IBOutlet id<ScaleSliderControlViewDelegate> delegate;


@end
