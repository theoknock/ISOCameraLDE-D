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
    
    [self setContentInset:UIEdgeInsetsMake(CGRectGetMinY(self.frame), [self inset], CGRectGetMaxY(self.frame), [self inset])];
    
    scaleSliderValueTextLayer = [CATextLayer new];
    [self.superview.layer addSublayer:scaleSliderValueTextLayer];
    
    [self.layer setNeedsDisplay];
    [self.layer setNeedsDisplayOnBoundsChange:YES];
}

- (CGFloat)inset
{
    return fabs(CGRectGetMidX(self.frame) - CGRectGetMinX(self.frame));
}

static double (^normalize)(float, float, float) = ^(float boundsX, float inset, float contentWidth)
{
    double value = (1.0 - 0.0) * ((boundsX + inset) - 0.0) / (contentWidth - 0.0) + 0.0;
    value = (value < 0.0) ? 0.0 : (value > 1.0) ? 1.0 : value;
    
    return value;
};

- (void)displayLayer:(CALayer *)layer
{
    NSMutableParagraphStyle *centerAlignedParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    centerAlignedParagraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *centerAlignedTextAttributes = @{NSForegroundColorAttributeName:[UIColor systemYellowColor],
                                                  NSFontAttributeName:[UIFont systemFontOfSize:14.0],
                                                  NSParagraphStyleAttributeName:centerAlignedParagraphStyle};
    
    NSString *valueString = [NSString stringWithFormat:@"%.2f", normalize(self.bounds.origin.x, [self inset], self.contentSize.width)];
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:valueString attributes:centerAlignedTextAttributes];
    
    
    [(CATextLayer *)scaleSliderValueTextLayer setOpaque:FALSE];
    [(CATextLayer *)scaleSliderValueTextLayer setAlignmentMode:kCAAlignmentCenter];
    [(CATextLayer *)scaleSliderValueTextLayer setWrapped:FALSE];
    ((CATextLayer *)scaleSliderValueTextLayer).string = attributedString;

    CGSize textLayerframeSize = [self suggestFrameSizeWithConstraints:self.frame.size forAttributedString:attributedString];
    CGRect textLayerFrame = CGRectMake(CGRectGetMidX(self.frame) - (textLayerframeSize.width * 0.5), CGRectGetMinY(self.frame), textLayerframeSize.width, textLayerframeSize.height);

    [(CATextLayer *)scaleSliderValueTextLayer setFrame:textLayerFrame];
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
