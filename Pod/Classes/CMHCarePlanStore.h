#import <CareKit/CareKit.h>

typedef void(^CMHRemoteSyncCompletion)(BOOL success, NSArray<NSError *> *_Nonnull errors);

@interface CMHCarePlanStore : OCKCarePlanStore

+ (nonnull instancetype)storeWithPersistenceDirectoryURL:(nonnull NSURL *)URL;

- (void)syncFromRemoteWithCompletion:(nullable CMHRemoteSyncCompletion)block;
- (void)clearLocalStore;

@end
