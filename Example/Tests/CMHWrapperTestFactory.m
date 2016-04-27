#import "CMHWrapperTestFactory.h"

@implementation CMHWrapperTestFactory

#pragma mark ORKTaskResult

+ (ORKTaskResult *)taskResult
{
    ORKTextQuestionResult *textQuestionResult = [ORKTextQuestionResult new];
    textQuestionResult.textAnswer = @"TestAnswer";

    ORKScaleQuestionResult *scaleQuestionResult = [ORKScaleQuestionResult new];
    scaleQuestionResult.scaleAnswer = [NSNumber numberWithFloat:1.16f];

    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"CMHTestStepIdentifier" results:@[textQuestionResult, scaleQuestionResult]];

    ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithIdentifier:@"CMHTestIdentifier"];
    taskResult.results = @[stepResult];

    return taskResult;
}

+ (BOOL)isEquivalent:(ORKTaskResult *)taskResult
{
    return [taskResult.identifier isEqualToString:@"CMHTestIdentifier"] &&
    [taskResult.firstResult isKindOfClass:[ORKStepResult class]] &&
    [taskResult.firstResult.identifier isEqualToString:@"CMHTestStepIdentifier"] &&
    [((ORKStepResult *)taskResult.firstResult).results[0] isKindOfClass:[ORKTextQuestionResult class]] &&
    [((ORKTextQuestionResult *)((ORKStepResult *)taskResult.firstResult).results[0]).textAnswer isEqualToString:@"TestAnswer"] &&
    [((ORKStepResult *)taskResult.firstResult).results[1] isKindOfClass:[ORKScaleQuestionResult class]] &&
    ((ORKScaleQuestionResult *)((ORKStepResult *)taskResult.firstResult).results[1]).scaleAnswer.floatValue == 1.16f;
}

#pragma mark NSDateComponents

+ (NSDateComponents *)testDateComponents
{
    NSDateComponents *comps = [NSDateComponents new];
    comps.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierHebrew];
    comps.timeZone = [NSTimeZone timeZoneWithName:@"Pacific/Honolulu"];
    comps.era = 1;
    comps.year = 5000;
    comps.month = 10;
    comps.day = 12;
    comps.hour = 7;
    comps.minute = 16;
    comps.second = 6;
    comps.nanosecond = 4;
    comps.weekday = 3;
    comps.weekdayOrdinal = 2;
    comps.quarter = 2;
    comps.weekOfMonth = 1;
    comps.weekOfYear = 40;
    comps.yearForWeekOfYear = 8;
    comps.leapMonth = NO;

    return comps;
}

+ (BOOL)isEquivalentToTestDateComponents:(NSDateComponents *)comps
{
    NSDateComponents *testComps = [self testDateComponents];

    BOOL isEqual = YES;
    isEqual = isEqual && [comps.calendar.calendarIdentifier isEqualToString:testComps.calendar.calendarIdentifier];
    isEqual = isEqual && [comps.timeZone.name isEqualToString:testComps.timeZone.name];
    isEqual = isEqual && comps.era == testComps.era;
    isEqual = isEqual && comps.year == testComps.year;
    isEqual = isEqual && comps.month == testComps.month;
    isEqual = isEqual && comps.day == testComps.day;
    isEqual = isEqual && comps.hour == testComps.hour;
    isEqual = isEqual && comps.minute == testComps.minute;
    isEqual = isEqual && comps.second == testComps.second;
    isEqual = isEqual && comps.nanosecond == testComps.nanosecond;
    isEqual = isEqual && comps.weekday == testComps.weekday;
    isEqual = isEqual && comps.weekdayOrdinal == testComps.weekdayOrdinal;
    isEqual = isEqual && comps.quarter == testComps.quarter;
    isEqual = isEqual && comps.weekOfMonth == testComps.weekOfMonth;
    isEqual = isEqual && comps.weekOfYear == testComps.weekOfYear;
    isEqual = isEqual && comps.yearForWeekOfYear == testComps.yearForWeekOfYear;
    isEqual = isEqual && comps.leapMonth == testComps.leapMonth;

    return isEqual;
}


@end