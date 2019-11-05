//
//  ScaleSliderScrollView.m
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/14/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ScaleSliderScrollView.h"

@implementation ScaleSliderScrollView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setContentInset:UIEdgeInsetsMake(0.0, [self inset], 0.0, [self inset])];
    
    scaleSliderValueTextLayer = [CATextLayer new];
    [self attributesForTextLayer:scaleSliderValueTextLayer];
    [self.superview.layer addSublayer:scaleSliderValueTextLayer];
    
    scaleSliderMinimumValueTextLayer = [CATextLayer new];
    [self attributesForTextLayer:scaleSliderMinimumValueTextLayer];
    [self.superview.layer addSublayer:scaleSliderMinimumValueTextLayer];
    
    scaleSliderMaximumValueTextLayer = [CATextLayer new];
    [self attributesForTextLayer:scaleSliderMaximumValueTextLayer];
    [self.superview.layer addSublayer:scaleSliderMaximumValueTextLayer];
    
    [self.layer setNeedsDisplay];
    [self.layer setNeedsDisplayOnBoundsChange:YES];
}

- (void)attributesForTextLayer:(CATextLayer *)textLayer
{
    [(CATextLayer *)textLayer setAllowsFontSubpixelQuantization:TRUE];
    [(CATextLayer *)textLayer setOpaque:FALSE];
    [(CATextLayer *)textLayer setAlignmentMode:kCAAlignmentCenter];
    [(CATextLayer *)textLayer setWrapped:FALSE];
}

- (CGFloat)inset
{
    return fabs(CGRectGetMidX(self.frame) - CGRectGetMinX(self.frame));
}

//- (void)displayLayer:(CALayer *)layer
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    NSMutableParagraphStyle *centerAlignedParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    centerAlignedParagraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *centerAlignedTextAttributes = @{NSForegroundColorAttributeName:[UIColor systemYellowColor],
                                                  NSFontAttributeName:[UIFont systemFontOfSize:14.0],
                                                  NSParagraphStyleAttributeName:centerAlignedParagraphStyle};
    
    NSString *valueString = [NSString stringWithFormat:@"%.2f", self.value.floatValue];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:valueString attributes:centerAlignedTextAttributes];
    ((CATextLayer *)scaleSliderValueTextLayer).string = attributedString;

    CGSize textLayerframeSize = [self suggestFrameSizeWithConstraints:self.frame.size forAttributedString:attributedString];
    CGRect textLayerFrame = CGRectMake(CGRectGetMidX(self.frame) - (textLayerframeSize.width * 0.5), CGRectGetMinY(self.frame), textLayerframeSize.width, textLayerframeSize.height);
    [(CATextLayer *)scaleSliderValueTextLayer setFrame:textLayerFrame];
    
    CGRect bounds = CGRectMake(CGRectGetMidX(self.frame) - (CGRectGetWidth(self.frame) * 0.5), 0.0, CGRectGetWidth(self.frame) * 2.0, CGRectGetHeight(self.frame));
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

- (CGSize)suggestFrameSizeWithConstraints:(CGSize)size forAttributedString:(NSAttributedString *)attributedString
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFMutableAttributedStringRef)attributedString);
    CFRange attributedStringRange = CFRangeMake(0, attributedString.length);
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, attributedStringRange, NULL, size, NULL);
    CFRelease(framesetter);
    
    return suggestedSize;
}

@end
