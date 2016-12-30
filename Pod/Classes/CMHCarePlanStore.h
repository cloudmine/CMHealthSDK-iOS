#import <CareKit/CareKit.h>

@interface CMHCarePlanStore : OCKCarePlanStore

+ (nonnull instancetype)storeWithPersistenceDirectoryURL:(NSURL *)URL;

@end
