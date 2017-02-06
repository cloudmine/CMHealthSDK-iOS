#import <CareKit/CareKit.h>

@interface CMHCarePlanStore : OCKCarePlanStore

+ (nonnull instancetype)storeWithPersistenceDirectoryURL:(nonnull NSURL *)URL;

- (void)fetchEventsTest;

@end
