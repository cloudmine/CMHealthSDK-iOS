#import "CMHCareTestFactory.h"

static NSString *const CMHIdentifierExerciseInterventionsGroup   = @"CMHExerciseInterventions";
static NSString *const CMHIdentifierInterventionHamstringStretch = @"CMHHamstringStretch";
static NSString *const CMHIdentifierSubjectiveAssessmentsGroup   = @"CMHSubjectiveAssessments";
static NSString *const CMHIdentifierAssessmentPainTrack          = @"CMHPainTrack";

@implementation CMHCareTestFactory

+ (OCKCarePlanActivity *)interventionActivity
{
    OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:[self weekAgoComponents] occurrencesPerDay:3];
    
    NSString *instructions = NSLocalizedString(@"With your feet spread shoulder width apart, gently bend at the waist reaching toward"
                                               "your feet until you feel tension. Stop and hold for 10-16 seconds.", nil);
    
    return [[OCKCarePlanActivity alloc] initWithIdentifier:CMHIdentifierInterventionHamstringStretch
                                           groupIdentifier:CMHIdentifierExerciseInterventionsGroup
                                                      type:OCKCarePlanActivityTypeIntervention
                                                     title:NSLocalizedString(@"Hamstring Stretch", nil)
                                                      text:NSLocalizedString(@"5 minutes", nil)
                                                 tintColor:[UIColor blueColor]
                                              instructions:instructions
                                                  imageURL:nil
                                                  schedule:schedule
                                          resultResettable:YES
                                                  userInfo:nil];
}

+ (OCKCarePlanActivity *)assessmentActivity
{
    OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:[self weekAgoComponents] occurrencesPerDay:1];
    
    return [[OCKCarePlanActivity alloc] initWithIdentifier:CMHIdentifierAssessmentPainTrack
                                           groupIdentifier:CMHIdentifierSubjectiveAssessmentsGroup
                                                      type:OCKCarePlanActivityTypeAssessment
                                                     title:NSLocalizedString(@"Pain", nil)
                                                      text:NSLocalizedString(@"Lower Back", nil)
                                                 tintColor:[UIColor redColor]
                                              instructions:nil
                                                  imageURL:nil
                                                  schedule:schedule
                                          resultResettable:YES
                                                  userInfo:nil];
}

+ (OCKCarePlanEventResult *)assessmentEventResult
{
    return [[OCKCarePlanEventResult alloc] initWithValueString:@"10" unitString:@"Pain Units" userInfo:@{@"Hello": @[@"World", @42]}];
}

+ (NSDateComponents *)todayComponents
{
    return [[NSDateComponents alloc] initWithDate:[NSDate new] calendar:[NSCalendar currentCalendar]];
}

+ (NSDateComponents *_Nonnull)weekInTheFutureComponents
{
    NSDate *weekishInTheFuture = [NSDate dateWithTimeIntervalSinceNow:(7*24*60*60)];
    return [[NSDateComponents alloc] initWithDate:weekishInTheFuture calendar:[NSCalendar currentCalendar]];
}

+ (NSDateComponents *_Nonnull)weekAgoComponents
{
    NSDate *weekAgoIsh = [NSDate dateWithTimeIntervalSinceNow:-(7*24*60*60)];
    return [[NSDateComponents alloc] initWithDate:weekAgoIsh calendar:[NSCalendar currentCalendar]];
}

@end
