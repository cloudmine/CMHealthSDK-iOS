#import "OCKCarePlanEvent+CMHealth.h"
#import "CMHInternalUser.h"
#import "CMHCareEvent.h"
#import "CMHErrorUtilities.h"

@implementation OCKCarePlanEvent (CMHealth)

- (NSString *)cmh_uniqueId
{
    return [NSString stringWithFormat:@"%@-%li-%li", self.activity.identifier,
            (long)self.occurrenceIndexOfDay, (long)self.numberOfDaysSinceStart];
}

- (void)cmh_saveWithUserId:(NSString *)cmhIdentifier completion:(CMHCareSaveCompletion)block
{
    CMHCareEvent *cmEvent = [[CMHCareEvent alloc] initWithEvent:self andUserId:cmhIdentifier];

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
