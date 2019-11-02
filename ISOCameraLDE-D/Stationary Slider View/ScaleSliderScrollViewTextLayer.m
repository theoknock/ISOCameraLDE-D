//
//  ScaleSliderScrollViewTextLayer.m
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/21/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ScaleSliderScrollViewTextLayer.h"

@implementation ScaleSliderScrollViewTextLayer

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        NSMutableParagraphStyle *centerAlignedParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        centerAlignedParagraphStyle.alignment                = NSTextAlignmentCenter;
        NSDictionary *centerAlignedTextAttributes            = @{NSForegroundColorAttributeName:[UIColor systemYellowColor],
                                                                 NSFontAttributeName:[UIFont systemFontOfSize:14.0],
                                                                 NSParagraphStyleAttributeName:centerAlignedParagraphStyle};
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"0.00"
                                                                               attributes:centerAlignedTextAttributes];
        [self setOpaque:FALSE];
        [self setAlignmentMode:kCAAlignmentCenter];
        [self setWrapped:TRUE];
        self.string = attributedString;
        
        CGSize textLayerframeSize = [self suggestFrameSizeWithConstraints:self.bounds.size forAttributedString:attributedString];
        //        CGRect buttonFrame = [[self cameraControlButtonRectForCameraProperty:cameraProperty] CGRectValue];
        //        CGRect buttonFrameInSuperView = [self.cameraControls convertRect:buttonFrame toView:self.cameraControls];
        //
        //        CGRect frame = CGRectMake(CGRectGetMidX(buttonFrameInSuperView) - (textLayerframeSize.width / 2.0), textLayerframeSize.height * 1.25, textLayerframeSize.width, textLayerframeSize.height);
        //        CGRect frame = CGRectMake(CGRectGetMidX([[self viewWithTag:[self selectedCameraProperty]] convertRect:[[self selectedCameraPropertyFrame] CGRectValue] toView:self]), /*(CGRectGetMidX([[self selectedCameraPropertyFrame] CGRectValue]).origin.x - ([[self selectedCameraPropertyFrame] CGRectValue].size.width / 2.0)) + 83.0*/, ((((CGRectGetMinY(self.bounds) + CGRectGetMidY(self.bounds)) / 2.0) + 6.0) + textLayerFrameY), 48.0, textLayerframeSize.height);
        
        CGRect textLayerFrame = CGRectMake(CGRectGetMidX(self.frame) - (textLayerframeSize.width * 0.5), CGRectGetMinY(self.frame), textLayerframeSize.width, textLayerframeSize.height);
        
        [self setFrame:textLayerFrame];
    }
    
    return self;
}

- (void)drawInContext:(CGContextRef)ctx
{
    CGRect bounds = [self bounds];
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
