#import <CMHealth/CMHealth.h>
#import "CMHTest-Secrets.h"

SpecBegin(CMHealth)

describe(@"CMHealthIntegration", ^{

    beforeAll(^{
        expect(CMHTestsAppId.length).to.beGreaterThan(0);
        expect(CMHTestsAppId).notTo.equal(@"REPLACE_WITH_AN_APP_ID_TO_USE_FOR_TESTING");

        expect(CMHTestsAPIKey.length).to.beGreaterThan(0);
        expect(CMHTestsAPIKey).notTo.equal(@"REPLACE_WITH_API_KEY");

        [CMHealth setAppIdentifier:CMHTestsAppId appSecret:CMHTestsAPIKey];

        [Expecta setAsynchronousTestTimeout:5];
        setAsyncSpecTimeout(5);

        waitUntil(^(DoneCallback done) {
            if([CMHUser currentUser].isLoggedIn) {
                [[CMHUser currentUser] logoutWithCompletion:^(NSError *error){
                    done();
                }];
            } else {
                done();
            }
        });

        expect([CMHUser currentUser].isLoggedIn).to.equal(NO);
    });

    it(@"should create a user and sign them up", ^{
        NSString *unixTime = [NSNumber numberWithInt:(int)[NSDate new].timeIntervalSince1970].stringValue;
        NSString *emailAddress = [NSString stringWithFormat:@"cmhealth+%@@cloudmineinc.com", unixTime];

        [[CMHUser currentUser] signUpWithEmail:emailAddress password:@"test-password1" andCompletion:^(NSError *error) {
        }];

        expect([CMHUser currentUser].isLoggedIn).will.equal(YES);
        expect([CMHUser currentUser].userData.email).will.equal(emailAddress);
    });

    it(@"should upload a user consent", ^{
        ORKTaskResult *consentResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"" taskRunUUID:[NSUUID new] outputDirectory:nil];
        ORKConsentSignatureResult *signatureResult = [ORKConsentSignatureResult new];
        signatureResult.consented = YES;
        signatureResult.signature = [ORKConsentSignature signatureForPersonWithTitle:nil
                                                                    dateFormatString:nil
                                                                    identifier:@"CMHTestIdentifier"
                                                                           givenName:@"John"
                                                                          familyName:@"Doe"
                                                                      signatureImage:[UIImage imageNamed:@"Test-Signature-Image.png"]
                                                                          dateString:nil];
        consentResult.results = @[signatureResult];

        __block NSError *uploadError = nil;
        [[CMHUser currentUser] uploadUserConsent:consentResult forStudyWithDescriptor:@"CMHTestDescriptor" andCompletion:^(NSError *error) {
            uploadError = error;
        }];

        expect(uploadError).will.beNil();
        expect([CMHUser currentUser].userData.familyName).will.equal(@"Doe");
        expect([CMHUser currentUser].userData.givenName).will.equal(@"John");
    });
    

    it(@"should pass", ^{
        expect(YES).to.beTruthy();
    });
});

SpecEnd

