#import <Foundation/Foundation.h>

@class CMHCareEvent;

@interface CMHCareSyncQueue : NSObject

- (void)enqueueUpdateEvent:(CMHCareEvent *)event;

@end
