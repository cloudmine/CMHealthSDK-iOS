#import <CareKit/CareKit.h>

@interface OCKCarePlanActivity (CMHealthCompare)

- (BOOL)isEqualExceptEndDate:(nullable OCKCarePlanActivity *)other;

@end
