//
//  UIButton+Value.h
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 11/5/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.


#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (Value)

@property(assign, nonatomic) NSNumber * value;

@property(assign, nonatomic) NSNumber * minimumValue;
@property(assign, nonatomic) NSNumber * maximumValue;

@end

NS_ASSUME_NONNULL_END
