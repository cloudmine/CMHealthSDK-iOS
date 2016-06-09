#import "OCKCarePlanEvent+CMHealth.h"
#import "CMHInternalUser.h"

@implementation OCKCarePlanEvent (CMHealth)

- (NSString *)cmh_objectId
{
    return [NSString stringWithFormat:@"%@-%li-%li-%@", self.activity.identifier,
            (long)self.occurrenceIndexOfDay, (long)self.numberOfDaysSinceStart, [CMHInternalUser currentUser].objectId];
}

@end
