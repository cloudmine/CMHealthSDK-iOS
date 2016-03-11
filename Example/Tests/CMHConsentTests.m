#import <Foundation/Foundation.h>
#import <CMHealth/CMHealth.h>
#import <CMHealth/CMHConsent_internal.h>
#import <CloudMine/CloudMine.h>
#import "CMHWrapperTestFactory.h"

static NSString *const TestDescriptor = @"CMHTestDescriptor";
static NSString *const TestFileName   = @"CMHTestFileName";

SpecBegin(CMHConsent)

describe(@"CMHConsent", ^{
    it(@"should retain the result, filename, and descriptor", ^{
        ORKTaskResult *taskResult = CMHWrapperTestFactory.taskResult;
        CMHConsent *consent = [[CMHConsent alloc] initWithConsentResult:taskResult
                                              andSignatureImageFilename:TestFileName
                                                 forStudyWithDescriptor:TestDescriptor];

        expect(consent.consentResult == taskResult).to.beTruthy();
        expect(consent.signatureImageFilename).to.equal(TestFileName);
        expect(consent.studyDescriptor).to.equal(TestDescriptor);
    });

    it(@"should encode and decode properly with NSCoder", ^{
        CMHConsent *origConsent = [[CMHConsent alloc] initWithConsentResult:CMHWrapperTestFactory.taskResult
                                                  andSignatureImageFilename:TestFileName
                                                     forStudyWithDescriptor:TestDescriptor];
        NSData *consentData = [NSKeyedArchiver archivedDataWithRootObject:origConsent];
        CMHConsent *codedConsent = [NSKeyedUnarchiver unarchiveObjectWithData:consentData];

        expect(codedConsent == origConsent).to.beFalsy();
        expect([CMHWrapperTestFactory isEquivalent:codedConsent.consentResult]).to.beTruthy();
        expect(codedConsent.studyDescriptor).to.equal(TestDescriptor);
        expect(codedConsent.signatureImageFilename).to.equal(TestFileName);
    });

    it(@"should encode and decode properly with CMCoder", ^{
        CMHConsent *origConsent = [[CMHConsent alloc] initWithConsentResult:CMHWrapperTestFactory.taskResult
                                                  andSignatureImageFilename:TestFileName
                                                     forStudyWithDescriptor:TestDescriptor];
        NSDictionary *encodedObjects = [CMObjectEncoder encodeObjects:@[origConsent]];
        CMHConsent *codedConsent = [CMObjectDecoder decodeObjects:encodedObjects].firstObject;

        expect(codedConsent == origConsent).to.beFalsy();
        expect([CMHWrapperTestFactory isEquivalent:codedConsent.consentResult]).to.beTruthy();
        expect(codedConsent.studyDescriptor).to.equal(TestDescriptor);
        expect(codedConsent.signatureImageFilename).to.equal(TestFileName);
    });
});

SpecEnd
