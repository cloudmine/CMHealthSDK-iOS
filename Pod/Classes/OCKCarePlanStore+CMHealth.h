#import <CareKit/CareKit.h>

typedef void(^CMHCarePlanActivityFetchCompletion)(NSArray<OCKCarePlanActivity *> *_Nonnull activities, NSError *_Nullable error);
typedef void(^CMHCarePlanSaveCompletion)(NSString *_Nullable uploadStatus, NSError *_Nullable error);
typedef void(^CMHCarePlanEventFetchCompletion)(BOOL success, NSArray<NSError *> *_Nonnull errors);

/**
 * This category adds methods to the CareKit framework's `OCKCarePlanStore` class.
 * The methods allows seamless fetching and saving of data which is persisted locally in 
 * the store to CloudMine's HIPAA compliant Connected Health Cloud.
 *
 *  @warning the CareKit component of this SDK is experimental and subject to change. Your
 *  feedback is welcomed!
 */
@interface OCKCarePlanStore (CMHealth)

/**
 *  Save all activities currently in the local store to CloudMine.
 *  Updates/overwrites the existing list of activites if there is one.
 *
 * @warning the CareKit component of this SDK is experimental and subject to change. Your
 *  feedback is welcomed!
 *
 *  @param block Executes when the request succeeds or fails with an error.
 */
- (void)cmh_saveActivtiesWithCompletion:(_Nullable CMHCarePlanSaveCompletion)block;

/**
 *  Fetch and return the list of `OCKCarePlanActivity` objects last saved to CloudMine.
 *
 *  @param block Executes when the request succeeds or fails with an error.
 */
- (void)cmh_fetchActivitiesWithCompletion:(_Nullable CMHCarePlanActivityFetchCompletion)block;

/**
 *  Convenience mehtod for removing all data from the local store.
 *  Because this method blocks on the main thread until completed, it is
 *  only appropriate in situations where no futher acion should be taken until the
 *  data is removed; for example: logging a user out.
 *
 *  @warning This method is destructive: all local data is removed!
 *
 *  @warning This method blocks on the current thread until completed

 *  @warning the CareKit component of this SDK is experimental and subject to change. Your
 *  feedback is welcomed!
 *
 *  @param block Executes when the request succeeds or fails with an error.
 */
- (NSArray<NSError *> *_Nonnull)cmh_clearLocalStoreSynchronously;

/**
 *  Fetch all `OCKCarePlanActivityEvent` instances previously saved to CloudMine
 *  and load them into the local store.
 *
 *  @warning the CareKit component of this SDK is experimental and subject to change. Your
 *  feedback is welcomed!
 *
 *  @param block Executes when the request succeeds or fails with an error.
 */
//- (void)cmh_fetchAndLoadAllEventsWithCompletion:(_Nullable CMHCarePlanEventFetchCompletion)block;

@end
