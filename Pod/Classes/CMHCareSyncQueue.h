#import <Foundation/Foundation.h>

@class CMHCareEvent;

@interface CMHCareSyncQueue : NSObject

- (void)enqueueUpdateEvent:(nonnull CMHCareEvent *)event;
- (void)runInBackgroundAfterQueueEmpties:(void(^_Nonnull)())block;

@end
