//
//  ScaleSliderScrollView.h
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/14/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScaleSliderScrollView : UIScrollView
{
    CATextLayer *scaleSliderValueTextLayer;
}

@end

NS_ASSUME_NONNULL_END
