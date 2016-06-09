#import <CareKit/CareKit.h>

typedef void(^CMHCarePlanActivityFetchCompletion)(NSArray<OCKCarePlanActivity *> *_Nonnull activities, NSError *_Nullable error);
typedef void(^CMHCarePlanSaveCompletion)(NSError *_Nullable error);

@interface OCKCarePlanStore (CMHealth)

- (void)cmh_fetchActivitiesWithCompletion:(_Nullable CMHCarePlanActivityFetchCompletion)block;
- (void)cmh_saveActivtiesWithCompletion:(_Nullable CMHCarePlanSaveCompletion)block;
- (NSArray<NSError *> *_Nonnull)cmh_clearLocalStoreSynchronously;

@end
