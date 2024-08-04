
#import <Foundation/Foundation.h>


@interface Utilities : NSObject
+ (void)debounced:(void(^)(void))block withDelay:(float)delay;
@end


@implementation Utilities

+ (void)debounced:(void (^)(void))block withDelay:(float)delay {

    static dispatch_source_t debounceTimer;

    if (debounceTimer) {
        dispatch_source_cancel(debounceTimer);
    }

    debounceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());

    dispatch_source_set_timer(debounceTimer,
                              dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC),
                              DISPATCH_TIME_FOREVER, 0);

    __block dispatch_source_t dt = debounceTimer;

    dispatch_source_set_event_handler(debounceTimer, ^{
        block();
        if (dt) {
            dispatch_source_cancel(dt);
            dt = nil;
        }
    });

    dispatch_resume(debounceTimer);
}

@end
