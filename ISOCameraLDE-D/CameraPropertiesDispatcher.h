//
//  CameraPropertiesDispatcher.h
//  ISOCameraLDE-B
//
//  Created by Xcode Developer on 10/11/19.
//  Copyright © 2019 James Bush. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//typedef NS_OPTIONS(NSUInteger, CameraProperty) {
//    CameraPropertyInvalid = 1 << 0,
//    CameraPropertyPosition = 1 << 1,
//    CameraPropertyRecord = 1 << 2,
//    CameraPropertyExposureDuration = 1 << 3,
//    CameraPropertyISO = 1 << 4,
//    CameraPropertyLensPosition = 1 << 5,
//    CameraPropertyTorchLevel = 1 << 6,
//    CameraPropertyVideoZoomFactor = 1 << 7,
//};

typedef enum : NSUInteger {
    CameraPropertyInvalid,
    CameraPropertyPosition,
    CameraPropertyRecord,
    CameraPropertyExposureDuration,
    CameraPropertyISO,
    CameraPropertyLensPosition,
    CameraPropertyTorchLevel,
    CameraPropertyVideoZoomFactor,
} CameraProperty;

static void * (^keyForCameraProperty)(CameraProperty property);

typedef struct {
    int *property;
    float *value;
} Context;

typedef struct {
    long *index;
} Key;

typedef void (^CameraPropertyNormalizedValue)(CameraProperty *property, float *normalizedValue);

@interface CameraPropertiesDispatcher : NSObject

+ (CameraPropertiesDispatcher *)dispatch;

@property (nonatomic, strong) __block dispatch_queue_t dispatch_source_queue;
@property (nonatomic, strong) __block dispatch_source_t dispatch_source;



@end

NS_ASSUME_NONNULL_END
