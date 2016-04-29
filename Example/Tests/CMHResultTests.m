#import <Foundation/Foundation.h>
#import <CMHealth/CMHResult.h>
#import "CMHWrapperTestFactory.h"

static NSString *const TestDescriptor = @"CMHTestDescriptor";

SpecBegin(CMHResult)

describe(@"CMHResult", ^{
    it(@"should retain the result and descriptor", ^{
        ORKTaskResult *orkTaskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"TestIdentifier" taskRunUUID:[NSUUID UUID] outputDirectory:nil];
        CMHResult *result = [[CMHResult alloc] initWithResearchKitResult:orkTaskResult andStudyDescriptor:TestDescriptor];

        expect(result.rkResult).to.equal(orkTaskResult);
        expect(result.studyDescriptor).to.equal(TestDescriptor);
    });

    it(@"should encode and decode properly with NSCoder", ^{
        CMHResult *origResult = [[CMHResult alloc] initWithResearchKitResult:CMHWrapperTestFactory.taskResult andStudyDescriptor:TestDescriptor];
        NSData *resultData = [NSKeyedArchiver archivedDataWithRootObject:origResult];
        CMHResult *codedResult = [NSKeyedUnarchiver unarchiveObjectWithData:resultData];

        expect(codedResult == origResult).to.beFalsy();
        expect([CMHWrapperTestFactory isEquivalent:(ORKTaskResult *)codedResult.rkResult]).to.beTruthy();
        expect(codedResult.studyDescriptor).to.equal(TestDescriptor);
    });

    it(@"should encode and decode properly with CMCoder", ^{
        CMHResult *origResult = [[CMHResult alloc] initWithResearchKitResult:CMHWrapperTestFactory.taskResult andStudyDescriptor:TestDescriptor];
        NSDictionary *encodedObjects = [CMObjectEncoder encodeObjects:@[origResult]];
        CMHResult *codedResult = [CMObjectDecoder decodeObjects:encodedObjects].firstObject;

        expect(codedResult == origResult).to.beFalsy();
        expect([CMHWrapperTestFactory isEquivalent:(ORKTaskResult *)codedResult.rkResult]).to.beTruthy();
        expect(codedResult.studyDescriptor).to.equal(TestDescriptor);
    });
});

SpecEnd
