#import "OCKCarePlanEvent+CMHealth.h"
#import "CMHInternalUser.h"
#import "CMHCareEvent.h"
#import "CMHErrorUtilities.h"

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

        NSError *saveError = [CMHErrorUtilities errorForUploadWithObjectId:cmEvent.objectId uploadResponse:response];
        if (nil != saveError) {
            block(nil, saveError);
            return;
        }

        block(response.uploadStatuses[cmEvent.objectId], nil);
    }];
}

@end
