#import <CareKit/CareKit.h>

@interface OCKCarePlanStore (CMHealth)

- (NSArray<NSError *> *_Nonnull)cmh_clearLocalStoreSynchronously;

@end
