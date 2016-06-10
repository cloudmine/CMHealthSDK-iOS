#import <CareKit/CareKit.h>

typedef void(^CMHCarePlanActivityFetchCompletion)(NSArray<OCKCarePlanActivity *> *_Nonnull activities, NSError *_Nullable error);
typedef void(^CMHCarePlanSaveCompletion)(NSString *_Nullable uploadStatus, NSError *_Nullable error);
typedef void(^CMHCarePlanEventFetchCompletion)(BOOL success, NSArray<NSError *> *_Nonnull errors);

@interface OCKCarePlanStore (CMHealth)

- (void)cmh_fetchActivitiesWithCompletion:(_Nullable CMHCarePlanActivityFetchCompletion)block;
- (void)cmh_saveActivtiesWithCompletion:(_Nullable CMHCarePlanSaveCompletion)block;
- (NSArray<NSError *> *_Nonnull)cmh_clearLocalStoreSynchronously;

- (void)cmh_fetchAndLoadAllEventsWithCompletion:(_Nullable CMHCarePlanEventFetchCompletion)block;

@end
