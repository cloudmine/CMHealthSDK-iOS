#import "CMHWrapperTestFactory.h"

@implementation CMHWrapperTestFactory

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

@end