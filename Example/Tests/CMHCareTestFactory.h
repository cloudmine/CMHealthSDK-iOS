#import <CMHealth/CMHealth.h>

@interface CMHCareTestFactory : NSObject

+ (OCKCarePlanActivity *)interventionActivity;
+ (OCKCarePlanActivity *)assessmentActivity;
+ (NSDateComponents *)todayComponents;
+ (OCKCarePlanEventResult *)assessmentEventResult;

@end
