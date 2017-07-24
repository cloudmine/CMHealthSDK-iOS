#import "OCKCareSchedule+CMHealth.h"

@implementation OCKCareSchedule (CMHealthCompare)

- (BOOL)isEqualExceptEndDate:(nullable OCKCareSchedule *)other
{
    if (nil == other || ![other isKindOfClass:[OCKCareSchedule class]]) {
        return NO;
    }
    
    return (areEqual(self.startDate, other.startDate) &&
            areEqual(self.occurrences, other.occurrences) &&
            areEqual(self.thresholds, other.thresholds) &&
            (self.timeUnitsToSkip == other.timeUnitsToSkip));
}

@end
