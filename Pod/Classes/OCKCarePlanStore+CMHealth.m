#import "OCKCarePlanStore+CMHealth.h"
#import "CMHDisptachUtils.h"

@implementation OCKCarePlanStore (CMHealth)

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
