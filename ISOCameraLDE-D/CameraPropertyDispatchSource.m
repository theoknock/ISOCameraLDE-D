//
//  CameraPropertyDispatchSource.m
//  ISOCameraLDE-D
//
//  Created by Xcode Developer on 10/19/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "CameraPropertyDispatchSource.h"

@implementation CameraPropertyDispatchSource
//
//static CameraPropertyDispatchSource * _dispatcher;
//+ (CameraPropertyDispatchSource *)dispatcher { return _dispatcher; }
//+ (void)setDispatcher:(CameraPropertyDispatchSource *)dispatcher { _dispatcher = dispatcher; }

+ (CameraPropertyDispatchSource *)dispatcher
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    static CameraPropertyDispatchSource *_sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^ {
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

static dispatch_queue_t _dispatch_source_queue_value_setter;
+ (dispatch_queue_t)dispatch_source_queue_value_setter { return _dispatch_source_queue_value_setter; };
+ (void)setDispatch_source_queue_value_setter:(dispatch_queue_t)dispatch_source_queue_value_setter { _dispatch_source_queue_value_setter = dispatch_source_queue_value_setter; }

static dispatch_source_t _dispatch_source_value_setter;
+ (dispatch_source_t)dispatch_source_value_setter { return _dispatch_source_value_setter; };
+ (void)setDispatch_source_value_setter:(dispatch_source_t)dispatch_source_value_setter {
    dispatch_source_set_event_handler(dispatch_source_value_setter, ^{
        CameraProperty p = (CameraProperty)dispatch_source_get_data(dispatch_source_value_setter);
        void * value = dispatch_queue_get_specific(_dispatch_source_queue_value_setter, CameraPropertyValueKey);
        float v = *(float *)&value;
        printf("\n\tp: %lu\tv: %f\n", p, v);
    });
    dispatch_set_target_queue(dispatch_source_value_setter, _dispatch_source_queue_value_setter);
    dispatch_resume(dispatch_source_value_setter);
    
    _dispatch_source_value_setter = dispatch_source_value_setter;
}


/// <#Description#>
- (instancetype)init
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super init];
    
    if (self)
    {
//        dispatch_queue_t serial_queue = dispatch_queue_create("com.wc.myQueue1", DISPATCH_QUEUE_SERIAL);
        // Note: set context data for private serial queue
    
        
//        [self dispatch_source_queue_value_getter];
//        [self dispatch_source_value_getter];
//        [CameraPropertyDispatchSource setDispatch_source_queue_value_setter:dispatch_queue_create_with_target("dispatch_source_queue_value_setter", DISPATCH_QUEUE_CONCURRENT, dispatch_get_main_queue())];
//        [CameraPropertyDispatchSource setDispatch_source_value_setter:dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, _dispatch_source_queue_value_setter)];

    }
    return self;
}


- (dispatch_queue_t)dispatch_source_queue_value_getter
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    __block dispatch_queue_t q = self->_dispatch_source_queue_value_getter;
    if (!q)
    {
        q = dispatch_get_main_queue(); //dispatch_queue_create("com.wc.myQueue1", DISPATCH_QUEUE_SERIAL);//dispatch_queue_create_with_target("dispatch_source_queue_value_getter", DISPATCH_QUEUE_CONCURRENT, dispatch_get_main_queue());
        self->_dispatch_source_queue_value_getter = q;
    }
    
    return q;
}


- (dispatch_source_t)dispatch_source_value_getter
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    __block dispatch_source_t dispatch_source = self->_dispatch_source_value_getter;
    if (!dispatch_source)
    {
        dispatch_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_REPLACE, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(dispatch_source, ^{
            void *contextData1 = dispatch_queue_get_specific(dispatch_get_main_queue(), &CameraPropertyValueKey);
            if (contextData1 != NULL) {
                NSLog(@"contextData1: %@", contextData1);
            }
            else {
                NSLog(@"contextData1 is NULL");
            }
//            CameraProperty p = (CameraProperty)dispatch_source_get_data(dispatch_source);
//            void * property = &p;
//            void * value = dispatch_queue_get_specific(dispatch_queue, CameraPropertyValueKey);
//            float v = *(float *)&value;
//            printf("\n\tp: %lu\tv: %f\n", p, v);
        });
        
        dispatch_set_target_queue(dispatch_source, dispatch_get_main_queue());
        dispatch_resume(dispatch_source);
        self->_dispatch_source_value_getter = dispatch_source;
    }
    
    return dispatch_source;
}

void (^(^event_handler)(dispatch_source_t, CameraProperty))(void) = ^(dispatch_source_t dispatch_source, CameraProperty property) {
    return ^{
        dispatch_source_merge_data(dispatch_source, property);
    };
};

/*
void (^(^(^(^(^block)(void))(void))(float (^__strong)(CameraProperty)))(CameraProperty))(void) = ^{
    return ^{
        return ^(float (^cameraPropertyValue)(CameraProperty)) {
            return ^ (CameraProperty property) {
                return ^{
                    cameraPropertyValue(property);
                };
            };
        };
    };
};

void (^(^(^(^(^block2)(void))(CameraProperty))(void))(float (^__strong)(CameraProperty)))(void) = ^{
//    return ^{
        return ^ (CameraProperty property) {
            return ^{
                return ^(float (^cameraPropertyValue)(CameraProperty)) {
                    return ^{
                        cameraPropertyValue(property);
                    };
                };
            };
        };
//    };
};

dispatch_source_event_parameter_value event_handler_parameter_value = ^float (CameraProperty property) {
return (float)property;
};

dispatch_source_event_parameter event_handler_parameter = ^(float (^dispatch_source_event_parameter_value)(CameraProperty)) {
return ^float(CameraProperty property) {
return dispatch_source_event_parameter_value(property);
};
};

dispatch_source_event_handler event_handler = ^(float (^dispatch_source_event_parameter_value)(CameraProperty)) {
return ^ {

};
};
*/

@end
