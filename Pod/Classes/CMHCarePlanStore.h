#import <CareKit/CareKit.h>
#import "CMHCareSyncBlocks.h"

typedef void(^CMHFetchPatientsCompletion)(BOOL success, NSArray<OCKPatient *> *_Nonnull patients, NSArray<NSError *> *_Nonnull errors);

@interface CMHCarePlanStore : OCKCarePlanStore

+ (nonnull instancetype)storeWithPersistenceDirectoryURL:(nonnull NSURL *)URL;
+ (void)fetchAllPatientsWithCompletion:(nonnull CMHFetchPatientsCompletion)block;

- (void)syncFromRemoteWithCompletion:(nullable CMHRemoteSyncCompletion)block;
- (void)clearLocalStore;

@end
