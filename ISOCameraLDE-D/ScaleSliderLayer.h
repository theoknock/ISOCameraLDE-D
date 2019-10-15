//
//  ScaleSliderLayer.h
//  ISOCameraLDE
//
//  Created by Xcode Developer on 10/3/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ScaleSliderLayerDelegate <NSObject>

@property (assign) NSInteger ticks;

@end

@interface ScaleSliderLayer : CALayer

@property (weak, nonatomic) id<ScaleSliderLayerDelegate> scaleSliderLayerDelegate;

@end

NS_ASSUME_NONNULL_END
