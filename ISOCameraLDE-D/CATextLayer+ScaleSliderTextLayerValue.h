//
//  CATextLayer+ScaleSliderTextLayerValue.h
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/21/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface CATextLayer (ScaleSliderTextLayerValue)

@property (nonatomic, strong) NSNumber *scaleSliderValue;

@end

NS_ASSUME_NONNULL_END
