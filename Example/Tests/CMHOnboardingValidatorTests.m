#import <Foundation/Foundation.h>
#import <CMHealth/CMHealth.h>
#import <CMHealth/CMHOnboardingValidator.h>
#import <CMHealth/CMHRegistrationData.h>

@interface CMHOnboardingValidatorTestFactory : NSObject
+ (ORKConsentSignatureResult *)validSignatureResult;
+ (ORKConsentSignature *)validSignature;
+ (ORKCollectionResult *)registrationResult;
@end

@implementation CMHOnboardingValidatorTestFactory

+ (ORKConsentSignatureResult *)validSignatureResult
{
    ORKConsentSignatureResult *signatureResult = [ORKConsentSignatureResult new];
    signatureResult.consented = YES;
    signatureResult.signature = CMHOnboardingValidatorTestFactory.validSignature;

    return signatureResult;
}

+ (ORKConsentSignature *)validSignature
{
    return [ORKConsentSignature signatureForPersonWithTitle:nil
                                           dateFormatString:nil
                                                 identifier:@"CMHTestIdentifier"
                                                  givenName:@"John"
                                                 familyName:@"Doe"
                                             signatureImage:[UIImage imageNamed:@"Test-Signature-Image.png"]
                                                 dateString:nil];
}

+ (ORKCollectionResult *)registrationResult
{
    ORKTextQuestionResult *emailResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierEmail];
    emailResult.textAnswer = @"test@test.com";

    ORKTextQuestionResult *passwordResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierPassword];
    passwordResult.textAnswer = @"testpassword123";

    ORKCollectionResult *regResult = [[ORKCollectionResult alloc] initWithIdentifier:@"CMHRegistrationTestResult"];
    regResult.results = @[emailResult, passwordResult];

    return regResult;
}

@end

SpecBegin(CMHOnboardingValidator)

describe(@"CMHOnboardingValidator", ^{

#pragma mark Consent Signature

    it(@"should produce an error for a nil consent result", ^{
        NSError *error = nil;

        ORKConsentSignature *signature = [CMHOnboardingValidator signatureFromConsentResults:nil error:&error];

        expect(signature).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserMissingConsent);
    });

    it(@"should produce an error for a consent result with no signature", ^{
        NSError *error = nil;

        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];

        ORKConsentSignature *signature = [CMHOnboardingValidator signatureFromConsentResults:taskResult error:&error];

        expect(signature).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserMissingSignature);
    });

    it(@"should produce an error if the user did not consent", ^{
        NSError *error = nil;

        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];

        ORKConsentSignatureResult *signatureResult = CMHOnboardingValidatorTestFactory.validSignatureResult;
        signatureResult.consented = NO;

        taskResult.results = @[signatureResult];

        ORKConsentSignature *signature = [CMHOnboardingValidator signatureFromConsentResults:taskResult error:&error];

        expect(signature).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserDidNotConsent);
    });

    it(@"should find a valid signature, even if the family and given name are not included", ^{
        NSError *error = nil;

        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];

        ORKConsentSignatureResult *signatureResult = CMHOnboardingValidatorTestFactory.validSignatureResult;
        signatureResult.signature.familyName = nil;
        signatureResult.signature.givenName = nil;

        taskResult.results = @[signatureResult];

        ORKConsentSignature *signature = [CMHOnboardingValidator signatureFromConsentResults:taskResult error:&error];

        expect(signature).notTo.beNil();
        expect(error).to.beNil();
    });

    it(@"should produce an error if the signature image is not included", ^{
        NSError *error = nil;

        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];

        ORKConsentSignatureResult *signatureResult = CMHOnboardingValidatorTestFactory.validSignatureResult;
        signatureResult.signature.signatureImage = nil;

        taskResult.results = @[signatureResult];

        ORKConsentSignature *signature = [CMHOnboardingValidator signatureFromConsentResults:taskResult error:&error];

        expect(signature).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserDidNotSign);
    });

    it(@"should find a valid signature if it is at the top level of the results", ^{
        NSError *error = nil;

        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];
        ORKConsentSignatureResult *signatureResult = CMHOnboardingValidatorTestFactory.validSignatureResult;
        taskResult.results = @[signatureResult];

        ORKConsentSignature *signature = [CMHOnboardingValidator signatureFromConsentResults:taskResult error:&error];

        expect(error).to.beNil();
        expect(signature).to.equal(signatureResult.signature);
    });

    it(@"should find a valid signature if it is arbitrarily nested", ^{
        NSError *error = nil;

        ORKTaskResult *topResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];
        ORKTaskResult *firstResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier1" taskRunUUID:[NSUUID new] outputDirectory:nil];
        ORKTaskResult *secondResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier2" taskRunUUID:[NSUUID new] outputDirectory:nil];
        ORKStepResult *finalResult = [[ORKStepResult alloc] initWithStepIdentifier:@"" results:nil];

        finalResult.results = @[ORKTextQuestionResult.new, CMHOnboardingValidatorTestFactory.validSignatureResult, ORKTextQuestionResult.new];
        secondResult.results = @[finalResult];
        topResult.results = @[firstResult, secondResult];

        ORKConsentSignature *signature = [CMHOnboardingValidator signatureFromConsentResults:topResult error:&error];

        expect(error).to.beNil();
        expect(signature).to.equal([(ORKConsentSignatureResult *)[finalResult.results objectAtIndex:1] signature]);
    });

#pragma mark Registration

    it(@"should produce an error for a nil registration result", ^{
        NSError *error = nil;

        CMHRegistrationData *regData = [CMHOnboardingValidator dataFromRegistrationResults:nil error:&error];

        expect(regData).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserMissingRegistration);
    });

    it(@"should produce an error for a registration result with no registration step", ^{
        NSError *error = nil;

        ORKTaskResult *regResult = [[ORKTaskResult alloc] initWithIdentifier:@"CMHTestIdentifier"];

        CMHRegistrationData *regData = [CMHOnboardingValidator dataFromRegistrationResults:regResult error:&error];

        expect(regData).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserMissingRegistration);
    });

    it(@"should find a valid registration result if it is at the top level of the results", ^{
        NSError *error = nil;

        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithIdentifier:@"CMHTestIdentifier"];
        taskResult.results = @[CMHOnboardingValidatorTestFactory.registrationResult];

        CMHRegistrationData *regData = [CMHOnboardingValidator dataFromRegistrationResults:taskResult error:&error];

        expect(error).to.beNil();
        expect(regData).notTo.beNil();
        expect(regData.email).to.equal(@"test@test.com");
        expect(regData.password).to.equal(@"testpassword123");
    });

    it(@"should find a valid registration result if it is arbitrarily nested", ^{
        NSError *error = nil;

        ORKTaskResult *topResult = [[ORKTaskResult alloc] initWithIdentifier:@"CMHTestIdentifier"];
        ORKTaskResult *firstResult = [[ORKTaskResult alloc] initWithIdentifier:@"CMHTestIdentifier1"];
        ORKTaskResult *secondResult = [[ORKTaskResult alloc] initWithIdentifier:@"CMHTestIdentifier2"];
        ORKStepResult *finalResult = [[ORKStepResult alloc] initWithStepIdentifier:@"CMHTestStepIdentifier" results:nil];

        finalResult.results = @[ORKTextQuestionResult.new, CMHOnboardingValidatorTestFactory.registrationResult, ORKTextQuestionResult.new];
        secondResult.results = @[finalResult];
        topResult.results = @[firstResult, secondResult];

        CMHRegistrationData *regData = [CMHOnboardingValidator dataFromRegistrationResults:topResult error:&error];

        expect(error).to.beNil();
        expect(regData).notTo.beNil();
        expect(regData.email).to.equal(@"test@test.com");
        expect(regData.password).to.equal(@"testpassword123");
    });
});

SpecEnd
