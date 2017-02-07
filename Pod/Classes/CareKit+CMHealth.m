#import "CareKit+CMHealth.h"
#import "CMHObjectUtilities.h"

@implementation OCKCarePlanActivity (CMHealth)

- (BOOL)isDataEquivalentOf:(OCKCarePlanActivity *_Nullable)other
{
    return cmhAreObjectsEqual(self.title, other.title) &&
    cmhAreObjectsEqual(self.text, other.text) &&
    cmhAreObjectsEqual(self.instructions, other.instructions) &&
    cmhAreObjectsEqual(self.schedule, other.schedule) &&
    (self.type == other.type) &&
    cmhAreObjectsEqual(self.identifier, other.identifier) &&
    cmhAreObjectsEqual(self.groupIdentifier, other.groupIdentifier) &&
    (self.resultResettable == other.resultResettable) &&
    cmhAreObjectsEqual(self.userInfo, other.userInfo);

}

@end

@implementation OCKCareSchedule (CMHealth)
@end

@implementation OCKCarePlanEventResult (CMHealth)
@end
