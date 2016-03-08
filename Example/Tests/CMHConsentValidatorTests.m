#import <Foundation/Foundation.h>
#import <CMHealth/CMHealth.h>
#import <CMHealth/CMHConsentValidator.h>

SpecBegin(CMHealthConsentValidator)

describe(@"CMHConsentValidator", ^{
    it(@"should produce an error for a nil consent task", ^{
        NSError *error = nil;

        ORKConsentSignature *signature = [CMHConsentValidator signatureFromConsentResults:nil error:&error];

        expect(signature).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserMissingConsent);
    });

    it(@"should produce an error for a task result with no signature", ^{
        NSError *error = nil;

        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];

        ORKConsentSignature *signature = [CMHConsentValidator signatureFromConsentResults:taskResult error:&error];

        expect(signature).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserMissingSignature);
    });

    it(@"should produce an error if the user did not consent", ^{
        NSError *error = nil;

        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];

        ORKConsentSignatureResult *signatureResult = [ORKConsentSignatureResult new];
        signatureResult.consented = NO;
        signatureResult.signature = [ORKConsentSignature signatureForPersonWithTitle:nil
                                                                    dateFormatString:nil
                                                                          identifier:@"CMHTestIdentifier"
                                                                           givenName:@"John"
                                                                          familyName:@"Doe"
                                                                      signatureImage:[UIImage imageNamed:@"Test-Signature-Image.png"]
                                                                          dateString:nil];
        taskResult.results = @[signatureResult];

        ORKConsentSignature *signature = [CMHConsentValidator signatureFromConsentResults:taskResult error:&error];

        expect(signature).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserDidNotConsent);
    });

    it(@"should produce an error if the family and given name are not included", ^{
        NSError *error = nil;

        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];

        ORKConsentSignatureResult *signatureResult = [ORKConsentSignatureResult new];
        signatureResult.consented = YES;
        signatureResult.signature = [ORKConsentSignature signatureForPersonWithTitle:nil
                                                                    dateFormatString:nil
                                                                          identifier:@"CMHTestIdentifier"
                                                                           givenName:nil
                                                                          familyName:nil
                                                                      signatureImage:[UIImage imageNamed:@"Test-Signature-Image.png"]
                                                                          dateString:nil];
        taskResult.results = @[signatureResult];

        ORKConsentSignature *signature = [CMHConsentValidator signatureFromConsentResults:taskResult error:&error];

        expect(signature).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserDidNotProvideName);
    });

    it(@"should produce an error if the signature image is not included", ^{
        NSError *error = nil;

        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];

        ORKConsentSignatureResult *signatureResult = [ORKConsentSignatureResult new];
        signatureResult.consented = YES;
        signatureResult.signature = [ORKConsentSignature signatureForPersonWithTitle:nil
                                                                    dateFormatString:nil
                                                                          identifier:@"CMHTestIdentifier"
                                                                           givenName:@"John"
                                                                          familyName:@"Doe"
                                                                      signatureImage:nil
                                                                          dateString:nil];
        taskResult.results = @[signatureResult];

        ORKConsentSignature *signature = [CMHConsentValidator signatureFromConsentResults:taskResult error:&error];

        expect(signature).to.beNil();
        expect(error).notTo.beNil();
        expect(error.code).to.equal(CMHErrorUserDidNotSign);
    });
});

SpecEnd
