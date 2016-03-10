#import <Foundation/Foundation.h>
#import <CMHealth/CMHResult.h>

static NSString *const TestDescriptor = @"CMHTestDescriptor";

@interface CMHResultTestFactory : NSObject
+ (ORKTaskResult *)taskResult;
@end

@implementation CMHResultTestFactory

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

SpecBegin(CMHResult)

describe(@"CMHResult", ^{
    it(@"should retain the result and descriptor", ^{
        ORKResult *orkResult = [[ORKResult alloc] initWithIdentifier:@"TestIdentifier"];
        CMHResult *result = [[CMHResult alloc] initWithResearchKitResult:orkResult andStudyDescriptor:TestDescriptor];

        expect(result.rkResult).to.equal(orkResult);
        expect(result.studyDescriptor).to.equal(TestDescriptor);
    });

    it(@"should encode and decode properly with NSCoder", ^{
        CMHResult *origResult = [[CMHResult alloc] initWithResearchKitResult:CMHResultTestFactory.taskResult andStudyDescriptor:TestDescriptor];
        NSData *resultData = [NSKeyedArchiver archivedDataWithRootObject:origResult];
        CMHResult *codedResult = [NSKeyedUnarchiver unarchiveObjectWithData:resultData];

        expect(codedResult == origResult).to.beFalsy();
        expect([CMHResultTestFactory isEquivalent:(ORKTaskResult *)codedResult.rkResult]).to.beTruthy();
        expect(codedResult.studyDescriptor).to.equal(TestDescriptor);
    });
});

SpecEnd
