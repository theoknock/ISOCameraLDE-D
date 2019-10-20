//
//  CameraPropertyDispatchSource.h
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/19/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static void * CameraPropertyValueKey = @"CameraPropertyValueKey";

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

typedef float (^dispatch_source_event_handler_parameter_value)(CameraProperty property);
typedef float (^_Nonnull(^dispatch_source_event_handler_parameter)(float (^dispatch_source_event_handler_parameter_value)(CameraProperty)))(CameraProperty);
typedef void (^_Nonnull(^dispatch_source_event_handler)(float (^dispatch_source_event_handler_parameter)(CameraProperty)))(void);
typedef void (^dispatch_source_event)(void);

typedef dispatch_source_event_handler_parameter_value _Nonnull (^value)(CameraProperty property);
typedef dispatch_source_event_handler_parameter _Nonnull (^parameter)(dispatch_source_event_handler_parameter_value value);
typedef dispatch_source_event_handler _Nonnull (^handler)(dispatch_source_event_handler_parameter parameter);
typedef dispatch_source_event _Nonnull (^event)(dispatch_source_event_handler handler);

@interface CameraPropertyDispatchSource : NSObject

//@property (class, nonatomic, strong, readwrite) CameraPropertyDispatchSource * dispatcher;
+ (CameraPropertyDispatchSource *)dispatcher;

@property (class, nonatomic, strong, readonly) dispatch_queue_t dispatch_source_queue_value_setter;
@property (class, nonatomic, strong, readonly) dispatch_source_t dispatch_source_value_setter;
@property (nonatomic, strong) __block dispatch_queue_t dispatch_source_queue_value_getter;
@property (nonatomic, strong) __block dispatch_source_t dispatch_source_value_getter;

@property (nonatomic, copy)   __block dispatch_source_event event;
@property (nonatomic, copy)   __block dispatch_source_event_handler handler;
@property (nonatomic, copy)   __block dispatch_source_event_handler_parameter parameter;
@property (nonatomic, copy)   __block dispatch_source_event_handler_parameter_value value;

@property (nonatomic, copy)   __block float (^dispatch_source_event_handler_parameter_value)(CameraProperty property);
@property (nonatomic, copy)   __block float (^_Nonnull(^dispatch_source_event_handler_parameter)(float (^dispatch_source_event_handler_parameter_value)(CameraProperty)))(CameraProperty);
@property (nonatomic, copy)   __block void (^_Nonnull(^dispatch_source_event_handler)(float (^dispatch_source_event_handler_parameter)(CameraProperty)))(void);
@property (nonatomic, copy)   __block void (^dispatch_source_event)(void);

@end

NS_ASSUME_NONNULL_END
