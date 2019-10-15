//
//  CameraPropertiesDispatcher.m
//  ISOCameraLDE-B
//
//  Created by Xcode Developer on 10/11/19.
//  Copyright © 2019 James Bush. All rights reserved.
//

#import "CameraPropertiesDispatcher.h"

@implementation CameraPropertiesDispatcher

//@synthesize cameraPropertyValueProvider = cameraPropertyValueProvider_;

+ (CameraPropertiesDispatcher *)dispatch
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    static CameraPropertiesDispatcher *_sharedInstance = nil;
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}


static void * key = "CameraPropertyVideoZoomFactor";
static void * value = "0.6";

// TO-DO: Create a shared instance for producer-consumer pairs;
//        the label parameter identifies the relationship between producers and consumers
//        use the label as a key for identifying a queue in a collection AND
//        as a key to a pair of arrays pointing to producer and consumer that share the queue
dispatch_queue_t (^dispatch_source_queue)(const char * _Nullable label) = ^dispatch_queue_t(const char * _Nullable label)
{
    dispatch_queue_t q = dispatch_queue_create_with_target(label, DISPATCH_QUEUE_CONCURRENT, dispatch_get_main_queue());
    return q;
};

void (^(^event_handler_block)(void))(void) = ^{
    return ^{
        
    };
};

float (^(^event_handler_block_param)(void (^)(void)))(CameraProperty) = ^(void(^event_handler_block)(void)) { //
     return ^float(CameraProperty cameraPropertyValue) {
        // block passed as the event handler to the dispatch source
         return 1.0;
    };
};

void (^(^dispatch_source_event_handler)(float (^)(CameraProperty)))(void) = ^(float (^cameraPropertyValue)(CameraProperty)) {
    return ^{
        float value = cameraPropertyValue(CameraPropertyLensPosition);
    };
};

dispatch_source_t (^dispatch_source)(void (^)(void)) = ^dispatch_source_t(void (^handler)(void))
{
    dispatch_queue_t queue   = dispatch_source_queue("Dispatch Queue");
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(source, dispatch_source_event_handler(event_handler_block_param(event_handler_block())));
    dispatch_set_target_queue(source, queue);
    dispatch_resume(source);
    
    return source;
};



- (instancetype)init
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super init];
    
    if (self)
    {
        static void * key = "CameraPropertyVideoZoomFactor";
        static void * value = "0.6";
        dispatch_queue_t queue = self.dispatch_source_queue;
        dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(source, ^{
            NSLog(@"CameraProperty %lu", dispatch_source_get_data(source));
            dispatch_async(queue, ^{
                NSLog(@"%s", dispatch_queue_get_specific(queue, key));
            });
        });
        dispatch_set_target_queue(source, queue);
        dispatch_resume(source);
        
        dispatch_queue_set_specific(queue, key, (void *)value, NULL);
        dispatch_source_merge_data(source, CameraPropertyVideoZoomFactor);
    }
    
    return self;
}

- (dispatch_queue_t)dispatch_source_queue
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    __block dispatch_queue_t q = self->_dispatch_source_queue;
    if (!q)
    {
        q = dispatch_queue_create_with_target("", DISPATCH_QUEUE_CONCURRENT, dispatch_get_main_queue());
        self->_dispatch_source_queue = q;
    }
    
    return q;
}

- (dispatch_source_t)dispatch_source
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    __block dispatch_source_t dispatch_source = self->_dispatch_source;
    __block dispatch_queue_t dispatch_queue = self->_dispatch_source_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_queue);
        dispatch_source_set_event_handler(dispatch_source, ^{
            
        });
        
        dispatch_set_target_queue(dispatch_source, dispatch_queue);
        dispatch_resume(dispatch_source);
        self->_dispatch_source = dispatch_source;
    });
    
    return dispatch_source;
}

- (dispatch_source_t)cameraPropertyChangesQueueEvent
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    __block dispatch_source_t dispatch_source = self->_dispatch_source;
    __block dispatch_queue_t dispatch_queue = self->_dispatch_source_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_queue);
        dispatch_source_set_event_handler(dispatch_source, ^{
            dispatch_async(dispatch_queue, ^{
                Key *key = (Key *)dispatch_source_get_data(dispatch_source);
                Context *context = (Context *)dispatch_get_specific(key->index);
                CameraProperty property = (CameraProperty)(*context->property);
                float value = *context->value;
                
                if (context != NULL)
                {
                    NSLog(@"property: %lu\tvalue: %f", property, value);
                    free((void *)context);
                } else {
                    NSLog(@"%s", __PRETTY_FUNCTION__);
                }
            });
        });
        
        dispatch_set_target_queue(dispatch_source, dispatch_queue);
        dispatch_resume(dispatch_source);
        self->_dispatch_source = dispatch_source;
    });
    
    return dispatch_source;
}
// Producer sends a
float normalize(float unscaledNum, float minAllowed, float maxAllowed, float min, float max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
}

NSInteger productionCount;
- (void)setValue:(float)value forProperty:(CameraProperty)property
{
    NSLog(@"%s\tproperty: %lu\tvalue: %f", __PRETTY_FUNCTION__, property, value);
    //    [self scaleNormalizedCameraPropertyValue:^(CameraProperty * _Nonnull property, float * _Nonnull normalizedValue) {
    //
    //        *normalizedValue = normalize(normalizedValue, 0.0, normalized * property, 0.0, 1.0);
    //
    //    }];
    int p   = (int)property;
    float v = value;
    Context *context  = (Context *)malloc(sizeof(Context));
    context->property = &p;
    context->value    = &v;
    
    if (context != NULL)
    {
        long index = (long)productionCount++;
        Key *key   = (Key *)malloc(sizeof(Key));
        key->index = &index;
        
        dispatch_queue_set_specific(self->_dispatch_source_queue, key, context, NULL);
        dispatch_source_merge_data(self->_dispatch_source, index);
    }
}

// Consume


@end
