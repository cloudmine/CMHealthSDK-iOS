#import "OCKCarePlanEvent+CMHealth.h"
#import "CMHInternalUser.h"
#import "CMHCareEvent.h"

@implementation OCKCarePlanEvent (CMHealth)

- (NSString *)cmh_objectId
{
    return [NSString stringWithFormat:@"%@-%li-%li-%@", self.activity.identifier,
            (long)self.occurrenceIndexOfDay, (long)self.numberOfDaysSinceStart, [CMHInternalUser currentUser].objectId];
}

- (void)cmh_saveWithCompletion:(_Nullable CMHCareSaveCompletion)block
{
    CMHCareEvent *cmEvent = [[CMHCareEvent alloc] initWithEvent:self];

    [cmEvent saveWithUser:[CMStore defaultStore].user callback:^(CMObjectUploadResponse *response) {
        if (nil == block) {
            return;
        }

        // TODO: errors

        block(response.uploadStatuses[cmEvent.objectId], nil);
    }];
}

@end
