#import <CareKit/CareKit.h>

typedef void(^CMHCarePlanSaveCompletion)(NSError *_Nullable error);

@interface OCKCarePlanStore (CMHealth)

- (void)cmh_saveActivtiesWithCompletion:(_Nullable CMHCarePlanSaveCompletion)block;
- (NSArray<NSError *> *_Nonnull)cmh_clearLocalStoreSynchronously;

@end
