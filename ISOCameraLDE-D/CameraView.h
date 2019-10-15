//
//  CameraView.h
//  ISOCameraLDE
//
//  Created by Xcode Developer on 6/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class AVCaptureSession;

@interface CameraView : UIView

@property (nonatomic) AVCaptureSession *session;

@end

NS_ASSUME_NONNULL_END
