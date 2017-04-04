#import <Foundation/Foundation.h>

@class CMHCareEvent;
@class CMHCareActivity;

@interface CMHCareSyncQueue : NSObject

- (null_unspecified instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)initWithCMHIdentifier:(nonnull NSString *)cmhIdentifer;

- (void)incrementPreQueueCount;
- (void)enqueueUpdateEvent:(nonnull CMHCareEvent *)event;
- (void)enqueueUpdateActivity:(nonnull CMHCareActivity *)activity;
- (void)decrementPreQueueCount;

- (void)runInBackgroundAfterQueueEmpties:(void(^_Nonnull)())block;

@end
