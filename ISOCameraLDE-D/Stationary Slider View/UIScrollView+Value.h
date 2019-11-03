//
//  UIScrollView+Value.h
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/23/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (Value)


@property(assign, nonatomic) NSNumber * scaledValue;
@property(assign, nonatomic) NSNumber * value;

@property(assign, nonatomic) NSNumber * minimumValue;
@property(assign, nonatomic) NSNumber * maximumValue;

@end

NS_ASSUME_NONNULL_END
