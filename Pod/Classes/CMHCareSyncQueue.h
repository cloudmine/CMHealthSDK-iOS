#import <Foundation/Foundation.h>

@class CMHCareEvent;

@interface CMHCareSyncQueue : NSObject

+ (instancetype)sharedQueue;

- (void)enqueueUpdateEvent:(CMHCareEvent *)event;

@end
