#import <Foundation/Foundation.h>
#import "CMHCareSyncBlocks.h"

@class CMHCareEvent;
@class CMHCareActivity;
@class CMHCarePlanStore;

@interface CMHCareSyncQueue : NSObject

- (null_unspecified instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)initWithCMHIdentifier:(nonnull NSString *)cmhIdentifer;

- (void)incrementPreQueueCount;
- (void)enqueueUpdateEvent:(nonnull CMHCareEvent *)event;
- (void)enqueueUpdateActivity:(nonnull CMHCareActivity *)activity;
- (void)enqueueDeleteActivity:(nonnull CMHCareActivity *)activity;
- (void)decrementPreQueueCount;

- (void)enqueueFetchForStore:(nonnull CMHCarePlanStore *)store completion:(nullable CMHRemoteSyncCompletion)block;

@end
