#import <Foundation/Foundation.h>

@class CMHCareEvent;
@class CMHCareActivity;

@interface CMHCareSyncQueue : NSObject

- (void)enqueueUpdateEvent:(nonnull CMHCareEvent *)event;
- (void)enqueueUpdateActivity:(nonnull CMHCareActivity *)activity;
- (void)runInBackgroundAfterQueueEmpties:(void(^_Nonnull)())block;

@end
