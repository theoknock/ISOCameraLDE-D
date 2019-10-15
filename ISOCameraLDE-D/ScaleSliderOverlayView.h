//
//  ScaleSliderViewTop.h
//  ISOCameraLDE
//
//  Created by Xcode Developer on 10/6/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ScaleSliderOverlayViewDelegate <NSObject>

- (NSValue *)selectedCameraPropertyFrame;

@end

@interface ScaleSliderOverlayView : UIView

@property (nonatomic, assign, nullable, setter=setDelegate:) id<ScaleSliderOverlayViewDelegate> delegate;
@property (nonatomic, assign, setter=setSelectedCameraPropertyValue:, getter=selectedCameraPropertyValue) NSValue *selectedCameraPropertyValue;

@end

NS_ASSUME_NONNULL_END
