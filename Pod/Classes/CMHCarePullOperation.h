#import <Foundation/Foundation.h>
#import "CMHCareSyncBlocks.h"

@class CMHCarePlanStore;

@interface CMHCarePullOperation : NSOperation

- (nonnull instancetype)initWithStore:(nonnull CMHCarePlanStore *)store completion:(nullable CMHRemoteSyncCompletion)block;

@end
