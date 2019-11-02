//
//  UIControl+GaugeViewProtocol.h
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/25/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol GaugeViewDelegate <NSObject>

@required
@property(assign, nonatomic) NSNumber * value;
@property(assign, nonatomic) NSNumber * minimumValue;
@property(assign, nonatomic) NSNumber * maximumValue;

@end

@interface UIControl (GaugeViewProtocol)

@property (weak, nonatomic, getter=gaugeViewDelegate, setter=setGaugeViewDelegate:) id<GaugeViewDelegate> gaugeViewDelegate;

@end

NS_ASSUME_NONNULL_END
