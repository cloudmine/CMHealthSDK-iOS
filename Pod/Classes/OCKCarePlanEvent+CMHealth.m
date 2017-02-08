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

@end
