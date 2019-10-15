//
//  ScaleSliderLayerTop.h
//  ISOCameraLDE
//
//  Created by Xcode Developer on 10/6/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScaleSliderOverlayLayer : CALayer

- (instancetype)initWithMeasureIndicatorHorizontalOffset:(double)measurementIndicatorHorizontalOffset;

@property (assign, setter=setMeasurementIndicatorHorizontalOffset:) double measurementIndicatorHorizontalOffset;

@end

NS_ASSUME_NONNULL_END
