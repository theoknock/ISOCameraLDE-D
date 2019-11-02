//
//  CATextLayer+ScaleSliderTextLayerValue.m
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/21/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "CATextLayer+ScaleSliderTextLayerValue.h"

@implementation CATextLayer (ScaleSliderTextLayerValue)

@dynamic scaleSliderValue;

- (void)setScaleSliderValue:(NSNumber *)scaleSliderValue
{
    objc_setAssociatedObject(self, @selector(scaleSliderValue), scaleSliderValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)scaleSliderValue
{
    return objc_getAssociatedObject(self, @selector(scaleSliderValue));
}

@end
