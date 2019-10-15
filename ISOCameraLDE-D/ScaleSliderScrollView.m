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
    
    CGFloat inset = fabs(CGRectGetMidX(self.frame) - CGRectGetMinX(self.frame));
    [self setContentInset:UIEdgeInsetsMake(CGRectGetMinY(self.frame), inset, CGRectGetMaxY(self.frame), inset)];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
