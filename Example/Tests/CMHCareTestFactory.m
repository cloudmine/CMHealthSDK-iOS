#import "CMHCareTestFactory.h"

static NSString *const CMHIdentifierExerciseInterventionsGroup   = @"CMHExerciseInterventions";
static NSString *const CMHIdentifierMedicationInterventionsGroup = @"CMHMedicationInterventions";
static NSString *const CMHIdentifierInterventionHamstringStretch = @"CMHHamstringStretch";
static NSString *const CMHIdentifierInterventionPainKiller       = @"CMHPainKiller";

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
    OCKCareSchedule *schedule = [OCKCareSchedule dailyScheduleWithStartDate:[self weekAgoComponents]
                                                          occurrencesPerDay:2
                                                                 daysToSkip:1
                                                                    endDate:nil];
    NSString *instructions = NSLocalizedString(@"Take a 200 mg dose of Ibuprofen two times a day, "
                                               "once in the morning and another in the evening.", nil);
    
    
    return [[OCKCarePlanActivity alloc] initWithIdentifier:CMHIdentifierInterventionPainKiller
                                           groupIdentifier:CMHIdentifierMedicationInterventionsGroup
                                                      type:OCKCarePlanActivityTypeIntervention
                                                     title:NSLocalizedString(@"Ibuprofen", nil)
                                                      text:NSLocalizedString(@"200 mg, Morning/Evening", nil)
                                                 tintColor:[UIColor redColor]
                                              instructions:instructions
                                                  imageURL:nil
                                                  schedule:schedule
                                          resultResettable:YES
                                                  userInfo:nil];
}

+ (NSDateComponents *_Nonnull)weekAgoComponents
{
    NSDate *weekAgoIsh = [NSDate dateWithTimeIntervalSinceNow:-(7*24*60*60)];
    return [[NSDateComponents alloc] initWithDate:weekAgoIsh calendar:[NSCalendar currentCalendar]];
}

@end
