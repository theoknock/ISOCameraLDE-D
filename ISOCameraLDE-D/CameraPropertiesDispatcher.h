//
//  CameraPropertiesDispatcher.h
//  ISOCameraLDE-B
//
//  Created by Xcode Developer on 10/11/19.
//  Copyright © 2019 James Bush. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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

- (void)setValue:(float)value forProperty:(CameraProperty)property;

@end

NS_ASSUME_NONNULL_END
