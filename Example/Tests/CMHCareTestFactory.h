#import <CMHealth/CMHealth.h>

@interface CMHCareTestFactory : NSObject

+ (OCKCarePlanActivity *)interventionActivity;
+ (OCKCarePlanActivity *)assessmentActivity;
+ (NSDateComponents *)todayComponents;
+ (NSDateComponents *)weekInTheFutureComponents;
+ (OCKCarePlanEventResult *)assessmentEventResult;

+ (NSString *)genderString;
+ (NSDate *)dateOfBirth;
+ (NSDictionary *)userDataUserInfo;

@end
