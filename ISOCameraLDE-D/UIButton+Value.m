//
//  UIButton+Value.m
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 11/5/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "UIButton+Value.h"

@implementation UIButton (Value)

@dynamic minimumValue, maximumValue, value;

- (void)setMinimumValue:(NSNumber *)minimumValue
{
//    NSLog(@"minimum value\t%f", minimumValue.floatValue);
//    self.minimumValue = [NSNumber numberWithDouble:MIN(minimumValue.floatValue, self.maximumValue.floatValue)];
    return objc_setAssociatedObject(self, @selector(minimumValue), minimumValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)minimumValue
{
//    return [NSNumber numberWithDouble:MIN(self.minimumValue.floatValue, self.maximumValue.floatValue)];
    return objc_getAssociatedObject(self, @selector(minimumValue));
}

- (void)setMaximumValue:(NSNumber *)maximumValue
{
//    NSLog(@"maximumValue %f", maximumValue.floatValue);
//     NSLog(@"maximum value\t%f", maximumValue.floatValue);
//    self.maximumValue = [NSNumber numberWithDouble:MAX(maximumValue.floatValue, self.minimumValue.floatValue)];
    return objc_setAssociatedObject(self, @selector(maximumValue), maximumValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)maximumValue
{
   
//    return [NSNumber numberWithDouble:MAX(self.maximumValue.floatValue, self.minimumValue.floatValue)];
    return objc_getAssociatedObject(self, @selector(maximumValue));
}

- (NSNumber *)value
{
   return objc_getAssociatedObject(self, @selector(value));
}

- (void)setValue:(NSNumber *)value
{
//    NSLog(@"value %f", value.floatValue);
    return objc_setAssociatedObject(self, @selector(value), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
