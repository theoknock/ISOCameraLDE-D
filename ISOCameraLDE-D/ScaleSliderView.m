//
//  ScaleSliderView.m
//  ISOCameraLDE
//
//  Created by Xcode Developer on 10/3/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ScaleSliderView.h"
#import "ScaleSliderLayer.h"

@implementation ScaleSliderView

+ (Class)layerClass
{
    return [ScaleSliderLayer class];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
}


@end
