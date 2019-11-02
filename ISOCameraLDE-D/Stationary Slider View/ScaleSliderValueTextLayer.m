//
//  ScaleSliderValueTextLayerDelegate.m
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/21/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ScaleSliderValueTextLayer.h"

@implementation ScaleSliderValueTextLayer

- (void)drawInContext:(CGContextRef)ctx
{
    
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    CGRect bounds = [self frame];
    CGContextTranslateCTM(ctx, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
    
    CGFloat height_eighth = (CGRectGetHeight(bounds) / 8.0);
    CGFloat height_thirtyseconth = (CGRectGetHeight(bounds) / 16.0);
    CGContextSetStrokeColorWithColor(ctx, [[UIColor yellowColor] CGColor]);
    CGContextSetLineWidth(ctx, 2.0);
    CGContextMoveToPoint(ctx, CGRectGetMidX(bounds), (CGRectGetMinY(bounds) + height_eighth) - height_thirtyseconth);
    CGContextAddLineToPoint(ctx, CGRectGetMidX(bounds), (CGRectGetMidY(bounds) - height_eighth) - height_thirtyseconth);
    CGContextStrokePath(ctx);
}

- (CGSize)suggestFrameSizeWithConstraints:(CGSize)size forAttributedString:(NSAttributedString *)attributedString
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFMutableAttributedStringRef)attributedString);
    CFRange attributedStringRange = CFRangeMake(0, attributedString.length);
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, attributedStringRange, NULL, size, NULL);
    CFRelease(framesetter);
    
    return suggestedSize;
}


@end
