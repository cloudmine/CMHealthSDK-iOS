#import "CMHCarePlanStore.h"
#import "CMHUser.h"

@interface CMHCarePlanStore ()

- (nonnull instancetype)initWithPersistenceDirectoryURL:(nonnull NSURL*)URL andCMHIdentifier:(nonnull NSString*)cmhIdentifier;
- (void)runFetchWithCompletion:(nullable CMHRemoteSyncCompletion)block;

@end
