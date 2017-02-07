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
                block(nil, error);
            }
            return;
        }

        CMHActivityList *activityList = [[CMHActivityList alloc] initWithActivities:activities];

        [activityList saveWithUser:[CMUser currentUser] callback:^(CMObjectUploadResponse *response) {
            if (nil == block) {
                return;
            }

            NSError *saveError = [CMHErrorUtilities errorForUploadWithObjectId:activityList.objectId uploadResponse:response];
            if (nil != saveError) {
                block(nil, saveError);
                return;
            }

            block(response.uploadStatuses[activityList.objectId], nil);
        }];
    }];
}

- (void)cmh_fetchActivitiesWithCompletion:(_Nullable CMHCarePlanActivityFetchCompletion)block
{
    [[CMStore defaultStore] allUserObjectsOfClass:[CMHActivityList class] additionalOptions:nil callback:^(CMObjectFetchResponse *response) {
        NSError *fetchError = [CMHErrorUtilities errorForFetchWithResponse:response];
        if (nil == block) {
            return;
        }

        if (nil != fetchError) {
            block(@[], fetchError);
            return;
        }

        CMHActivityList *activityList = response.objects.firstObject;
        if (nil == activityList) {
            block(@[], nil);
            return;
        }

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

@end
