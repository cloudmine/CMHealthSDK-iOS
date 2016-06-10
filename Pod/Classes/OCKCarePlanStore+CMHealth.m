#import "OCKCarePlanStore+CMHealth.h"
#import <CloudMine/CloudMine.h>
#import "CMHDisptachUtils.h"
#import "CMHActivityList.h"
#import "CMHCareEvent.h"
#import "CMHMutedEventUpdater.h"
#import "CMHErrorUtilities.h"

@implementation OCKCarePlanStore (CMHealth)

- (void)cmh_saveActivtiesWithCompletion:(_Nullable CMHCarePlanSaveCompletion)block
{
    [self activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nullable error) {
        if (!success) {
            if (nil != block) {
                block(error);
            }
            return;
        }

        CMHActivityList *activityList = [[CMHActivityList alloc] initWithActivities:activities];

        [activityList saveWithUser:[CMUser currentUser] callback:^(CMObjectUploadResponse *response) {
            // TODO: Error handling

            if (nil != block) {
                block(nil);
            }
        }];
    }];
}

- (void)cmh_fetchActivitiesWithCompletion:(_Nullable CMHCarePlanActivityFetchCompletion)block
{
    [[CMStore defaultStore] allUserObjectsOfClass:[CMHActivityList class] additionalOptions:nil callback:^(CMObjectFetchResponse *response) {
        // TODO: Error checking/handling
        CMHActivityList *activityList = response.objects.firstObject;
        block(activityList.activities, nil);
    }];
}

- (NSArray<NSError *> *_Nonnull)cmh_clearLocalStoreSynchronously
{
    __block NSArray *allActivities = nil;
    __block NSError *fetchError = nil;
    __block BOOL fetchSuccess = NO;

    cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
        [self activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nullable error) {
            fetchSuccess = success;
            allActivities = activities;
            fetchError = error;
            done();
        }];
    });

    if (nil != fetchError) {
        return @[fetchError];
    }

    NSMutableArray *mutableErrors = [NSMutableArray new];

    for (OCKCarePlanActivity *activity in allActivities) {
        cmh_wait_until(^(CMHDoneBlock _Nonnull done) {
            [self removeActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
                if (!success) {
                    [mutableErrors addObject:error];
                    done();
                    return;
                }

                done();
            }];
        });
    }

    return [mutableErrors copy];
}

- (void)cmh_fetchAndLoadAllEventsWithCompletion:(_Nullable CMHCarePlanEventFetchCompletion)block
{
    CMStoreOptions *noLimitOption = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:-1]];

    [[CMStore defaultStore] allUserObjectsOfClass:[CMHCareEvent class] additionalOptions:noLimitOption callback:^(CMObjectFetchResponse *response) {
        NSError *fetchError = [CMHErrorUtilities errorForFetchWithResponse:response];
        if (nil != fetchError) {
            if (nil != block) {
                block(NO, @[fetchError]);
            }
            return;
        }

        NSArray <CMHCareEvent *> *wrappedEvents = response.objects;

        dispatch_queue_t updateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

        dispatch_async(updateQueue, ^{
            NSMutableArray<NSError *> *updateErrors = [NSMutableArray new];

            for (CMHCareEvent *wrappedEvent in wrappedEvents) {
                __block NSArray<OCKCarePlanEvent *> *storeEvents = nil;
                __block NSError *storeError = nil;

                cmh_wait_until(^(CMHDoneBlock _Nonnull done) {
                    [self eventsForActivity:wrappedEvent.activity date:wrappedEvent.date completion:^(NSArray<OCKCarePlanEvent *> * _Nonnull events, NSError * _Nullable error) {
                        storeEvents = events;
                        storeError = error;
                        done();
                    }];
                });

                if (nil != storeError) {
                    [updateErrors addObject:storeError];
                    continue;
                }

                for (OCKCarePlanEvent *anEvent in storeEvents) {
                    if (anEvent.occurrenceIndexOfDay != wrappedEvent.occurrenceIndexOfDay ||
                        [wrappedEvent isDataEquivalentOf:anEvent]) {
                        continue;
                    }

                    CMHMutedEventUpdater *updater = [[CMHMutedEventUpdater alloc] initWithCarePlanStore:self
                                                                                                  event:anEvent
                                                                                                 result:wrappedEvent.result
                                                                                                  state:wrappedEvent.state];
                    NSError *thisUpdateError = [updater performUpdate];

                    if (nil != thisUpdateError) {
                        [updateErrors addObject:thisUpdateError];
                    }
                }
            }

            if (nil == block) {
                return;
            }

            BOOL success = updateErrors.count < 1;
            block(success, [updateErrors copy]);
        });
    }];
}

@end
