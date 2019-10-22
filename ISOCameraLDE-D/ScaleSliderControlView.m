//
//  ScaleSliderControlView.m
//  ISOCameraLDE
//
//  Created by Xcode Developer on 10/3/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ScaleSliderControlView.h"

@implementation ScaleSliderControlView

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    //    NSUInteger index = [[touch gestureRecognizers] indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//    //        BOOL isTapGesture = ([(UIGestureRecognizer *)obj isKindOfClass:[UITapGestureRecognizer class]]) ? FALSE : TRUE;
//    //        *stop = isTapGesture;
//    //
//    //        return isTapGesture;
//    //    }];
//    //
//    //    BOOL shouldReceiveTouch = (index != NSNotFound) ? FALSE : TRUE;
//    //    NSLog(@"%@Gesture at index %lu %@ be received by ScaleSliderControlView", (shouldReceiveTouch) ? @"\t\t\t\t" : @"", index, (shouldReceiveTouch) ? @"should" : @"should not");
//    //
//    //    return shouldReceiveTouch;
//    
//    return (self.isHidden) ? FALSE : TRUE;
//}
//
//- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
//{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    __block BOOL isPointInsideButtonRect;
//    [[(__kindof UIStackView *)[self.superview viewWithTag:7] subviews] enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        isPointInsideButtonRect = ([obj isKindOfClass:[UIButton class]] && CGRectContainsPoint([obj frame], point) && [(UIButton *)obj isSelected]) ? TRUE : isPointInsideButtonRect;
//        *stop = isPointInsideButtonRect;
//        if (isPointInsideButtonRect) [self.delegate handleTouchForButtonWithCameraProperty:[(UIButton *)obj tag]];
////        dispatch_async(dispatch_get_main_queue(), ^{
////            [(UIButton *)obj setSelected:FALSE];
////            [(UIButton *)obj setHighlighted:FALSE];
//            
//            // TO-DO: Instead of setting properties for UIControls and passing events to their associated actions,
//            // create a required delegate method that takes one parameters (Camera Property), returns no values—
//            // it instructs the delegate to perform the same tasks here; the event need not be s upplied
////            [self.delegate cameraPropertyButtonEventHandler:(UIButton *)obj forEvent:event];
////        });
//    }];
//    //        BOOL isPointInsideButtonRect = ([[obj class] isKindOfClass:[UIButton class]] && CGRectContainsPoint([obj frame], point)) ? TRUE : FALSE;
//    return !isPointInsideButtonRect;
//}


@end
