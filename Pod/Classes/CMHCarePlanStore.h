#import <CareKit/CareKit.h>

typedef void(^CMHRemoteSyncCompletion)(BOOL success, NSArray<NSError *> *_Nonnull errors);

@interface CMHCarePlanStore : OCKCarePlanStore

+ (nonnull instancetype)storeWithPersistenceDirectoryURL:(nonnull NSURL *)URL;

- (void)syncRemoteEventsWithCompletion:(nullable CMHRemoteSyncCompletion)block;
- (void)syncRemoteActivitiesWithCompletion:(nullable CMHRemoteSyncCompletion)block;

@end
