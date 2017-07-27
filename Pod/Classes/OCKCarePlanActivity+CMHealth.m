#import "OCKCarePlanActivity+CMHealth.h"
#import "OCKCareSchedule+CMHealth.h"

@implementation OCKCarePlanActivity (CMHealthCompare)

- (BOOL)isEqualExceptEndDate:(nullable OCKCarePlanActivity *)other
{
    if (nil == other || ![other isKindOfClass:[OCKCarePlanActivity class]]) {
        return NO;
    }
    
    return (areEqual(self.title, other.title) &&
            areEqual(self.text, other.text) &&
            areEqual(self.instructions, other.instructions) &&
            [self.schedule isEqualExceptEndDate:other.schedule] &&
            (self.type == other.type) &&
            areEqual(self.identifier, other.identifier) &&
            areEqual(self.groupIdentifier, other.groupIdentifier) &&
            areEqual(self.imageURL, other.imageURL) &&
            (self.resultResettable == other.resultResettable) &&
            areEqual(self.userInfo, other.userInfo) &&
            areEqual(self.thresholds, other.thresholds) &&
            (self.optional == other.optional));
}

@end
