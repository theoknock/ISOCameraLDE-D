//
//  ScaleSliderLayerTop.m
//  ISOCameraLDE
//
//  Created by Xcode Developer on 10/6/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ScaleSliderOverlayLayer.h"

@implementation ScaleSliderOverlayLayer

@synthesize measurementIndicatorHorizontalOffset = _measurementIndicatorHorizontalOffset;

- (double)measurementIndicatorHorizontalOffset
{
    return self->_measurementIndicatorHorizontalOffset;
}

- (void)setMeasurementIndicatorHorizontalOffset:(double)measurementIndicatorHorizontalOffset
{
    self->_measurementIndicatorHorizontalOffset = measurementIndicatorHorizontalOffset;
    [self display];
//    //NSLog(@"measurementIndicatorHorizontalOffset %f", measurementIndicatorHorizontalOffset);
}

- (instancetype)initWithMeasureIndicatorHorizontalOffset:(double)measurementIndicatorHorizontalOffset
{
    self = [super init];
    
    if (self)
    {
        [self setMeasurementIndicatorHorizontalOffset:measurementIndicatorHorizontalOffset];
    }
    
    return self;
}

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
//    //NSLog(@"drawInContext %f", _measurementIndicatorHorizontalOffset);
    CGRect bounds = [self bounds];
    CGContextTranslateCTM(ctx, CGRectGetMinX(bounds), CGRectGetMinY(bounds));

    CGFloat height_eighth = (CGRectGetHeight(bounds) / 8.0);
    CGFloat height_thirtyseconth = (CGRectGetHeight(bounds) / 16.0);
    CGContextSetStrokeColorWithColor(ctx, [[UIColor yellowColor] CGColor]);
    CGContextSetLineWidth(ctx, 2.0);
//    //NSLog(@"measurementIndicatorHorizontalOffset %f", _measurementIndicatorHorizontalOffset);
    CGContextMoveToPoint(ctx, _measurementIndicatorHorizontalOffset /*CGRectGetMidX(bounds)*/, (CGRectGetMinY(bounds) + height_eighth) - height_thirtyseconth);
    CGContextAddLineToPoint(ctx, _measurementIndicatorHorizontalOffset /*CGRectGetMidX(bounds)*/, (CGRectGetMidY(bounds) - height_eighth) - height_thirtyseconth);
        CGContextStrokePath(ctx);
}

@end
