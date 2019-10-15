//
//  ScaleSliderLayer.m
//  ISOCameraLDE
//
//  Created by Xcode Developer on 10/3/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ScaleSliderLayer.h"

@implementation ScaleSliderLayer

- (CGColorRef)backgroundColor
{
    return [[UIColor clearColor] CGColor];
}

- (BOOL)isOpaque
{
    return FALSE;
}

- (void)drawInContext:(CGContextRef)ctx
{
//    //NSLog(@"%s", __PRETTY_FUNCTION__);
    CGRect bounds = [self bounds];
    CGContextTranslateCTM(ctx, CGRectGetMinX(bounds), CGRectGetMinY(bounds));

    CGFloat stepSize = (CGRectGetMaxX(bounds) / 100.0);
    CGFloat height_eighth = (CGRectGetHeight(bounds) / 8.0);
    CGFloat height_sixteenth = (CGRectGetHeight(bounds) / 16.0);
    CGFloat height_thirtyseconth = (CGRectGetHeight(bounds) / 16.0);
    for (int t = 0; t <= 100; t++) {
        CGFloat x = (CGRectGetMinX(bounds) + (stepSize * t));
        if (t % 10 == 0)
        {
            CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor] CGColor]);
            CGContextSetLineWidth(ctx, 0.625);
            CGContextMoveToPoint(ctx, x, (CGRectGetMinY(bounds) + height_eighth) - height_thirtyseconth);
            CGContextAddLineToPoint(ctx, x, (CGRectGetMidY(bounds) - height_eighth) - height_thirtyseconth);
        }
        else
        {
            CGContextSetStrokeColorWithColor(ctx, [[UIColor lightGrayColor] CGColor]);
            CGContextSetLineWidth(ctx, 0.375);
            CGContextMoveToPoint(ctx, x, (CGRectGetMinY(bounds) + (height_eighth + height_sixteenth)) - height_thirtyseconth);
            CGContextAddLineToPoint(ctx, x, (CGRectGetMidY(bounds) - (height_eighth + height_sixteenth)) - height_thirtyseconth);
        }
        
        CGContextStrokePath(ctx);
    }
}

@end
