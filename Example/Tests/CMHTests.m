#import <CMHealth/CMHealth.h>
#import "CMHTest-Secrets.h"

static NSString *const TestDescriptor = @"CMHTestDescriptor";

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

        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] signUpWithEmail:emailAddress password:@"test-password1" andCompletion:^(NSError *error) {
                done();
            }];
        });

        expect([CMHUser currentUser].isLoggedIn).to.equal(YES);
        expect([CMHUser currentUser].userData.email).to.equal(emailAddress);
    });

    it(@"should upload a user consent", ^{
        ORKTaskResult *consentResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];
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
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] uploadUserConsent:consentResult forStudyWithDescriptor:TestDescriptor andCompletion:^(NSError *error) {
                uploadError = error;
                done();
            }];
        });

        expect(uploadError).to.beNil();
        expect([CMHUser currentUser].userData.familyName).to.equal(@"Doe");
        expect([CMHUser currentUser].userData.givenName).to.equal(@"John");
    });

    it(@"should fetch a user's consent and signature image", ^{
        __block CMHConsent *fetchedConsent = nil;
        __block NSError *consentError = nil;

        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] fetchUserConsentForStudyWithDescriptor:TestDescriptor andCompletion:^(CMHConsent *consent, NSError *error) {
                fetchedConsent = consent;
                consentError = error;
                done();
            }];
        });


        expect(consentError).to.beNil();
        expect(fetchedConsent).toNot.beNil();
        expect(fetchedConsent.consentResult).toNot.beNil();

        ORKConsentSignature *signature = ((ORKConsentSignatureResult *)fetchedConsent.consentResult.results.firstObject).signature;

        expect(signature.givenName).to.equal([CMHUser currentUser].userData.givenName);
        expect(signature.familyName).to.equal([CMHUser currentUser].userData.familyName);

        __block UIImage *signatureImage = nil;
        __block NSError *fetchError = nil;

        waitUntil(^(DoneCallback done) {
            [fetchedConsent fetchSignatureImageWithCompletion:^(UIImage *image, NSError *error) {
                signatureImage = image;
                fetchError = error;
                done();
            }];
        });

        expect(fetchError).to.beNil();
        expect(signatureImage).toNot.beNil();
        expect(signatureImage.size.width).to.equal(1.0f);
        expect(signatureImage.size.height).to.equal(1.0f);
    });

    it(@"should return nothing for a consent that is not on file", ^{
        __block CMHConsent *fetchedConsent = nil;
        __block NSError *consentError = nil;

        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] fetchUserConsentForStudyWithDescriptor:@"IncorrectDescriptor" andCompletion:^(CMHConsent *consent, NSError *error) {
                fetchedConsent = consent;
                consentError = error;
                done();
            }];
        });

        expect(consentError).to.beNil();
        expect(fetchedConsent).to.beNil();
    });

    it(@"should upload a task result", ^{
        ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier"
                                                                      taskRunUUID:[NSUUID new]
                                                                  outputDirectory:nil];

        ORKScaleQuestionResult *scaleResult = [ORKScaleQuestionResult new];
        scaleResult.scaleAnswer = [NSNumber numberWithDouble:1.16];

        ORKBooleanQuestionResult *booleanResult = [ORKBooleanQuestionResult new];
        booleanResult.booleanAnswer = [NSNumber numberWithBool:YES];

        taskResult.results = @[scaleResult, booleanResult];

        __block NSString *uploadStatus = nil;
        __block NSError *uploadError = nil;

        waitUntil(^(DoneCallback done) {
            [taskResult cmh_saveToStudyWithDescriptor:TestDescriptor withCompletion:^(NSString *status, NSError *error) {
                uploadStatus = status;
                uploadError = error;
                done();
            }];
        });

        expect(uploadError).to.beNil();
        expect(uploadStatus).to.equal(@"created");
    });

    it(@"should fetch a result", ^{
        __block NSArray *fetchResults = nil;
        __block NSError *fetchError = nil;

        waitUntil(^(DoneCallback done) {
            [ORKTaskResult cmh_fetchUserResultsForStudyWithDescriptor:TestDescriptor withCompletion:^(NSArray *results, NSError *error) {
                fetchResults = results;
                fetchError = error;
                done();
            }];
        });

        expect(fetchError).to.beNil();
        expect(fetchResults.count).to.equal(1);
        expect([fetchResults.firstObject class]).to.equal([ORKTaskResult class]);

        ORKTaskResult *task = (ORKTaskResult *)fetchResults.firstObject;

        expect([task.results[0] class]).to.equal([ORKScaleQuestionResult class]);
        expect(((ORKScaleQuestionResult *)task.results[0]).scaleAnswer.doubleValue).to.equal(1.16);

        expect([task.results[1] class]).to.equal([ORKBooleanQuestionResult class]);
        expect(((ORKBooleanQuestionResult *)task.results[1]).booleanAnswer.boolValue).to.equal(YES);
    });

    it(@"should return emptry results for an unused descriptor", ^{
        __block NSArray *fetchResults = nil;
        __block NSError *fetchError = nil;

        waitUntil(^(DoneCallback done) {
            [ORKTaskResult cmh_fetchUserResultsForStudyWithDescriptor:@"IncorrectDescriptor" withCompletion:^(NSArray *results, NSError *error) {
                fetchResults = results;
                fetchError = error;
                done();
            }];
        });

        expect(fetchError).to.beNil();
        expect(fetchResults).notTo.beNil();
        expect(fetchResults.count).to.equal(0);
    });

    it(@"should upload two step results", ^{
        ORKTextQuestionResult *stepOneQuestionResult = [ORKTextQuestionResult new];
        stepOneQuestionResult.textAnswer = @"StepOne";
        ORKStepResult *resultOne = [[ORKStepResult alloc] initWithStepIdentifier:@"StepTestOne" results:@[stepOneQuestionResult]];

        ORKTextQuestionResult *stepTwoQuestionResult = [ORKTextQuestionResult new];
        stepTwoQuestionResult.textAnswer = @"StepTwo";
        ORKStepResult *resultTwo = [[ORKStepResult alloc] initWithStepIdentifier:@"StepTestTwo" results:@[stepTwoQuestionResult]];

        __block NSString *statusOne = nil;
        __block NSError *errorOne = nil;

        __block NSString *statusTwo = nil;
        __block NSError *errorTwo = nil;

        waitUntil(^(DoneCallback done){
            [resultOne cmh_saveToStudyWithDescriptor:@"StepOneDescriptor" withCompletion:^(NSString *status, NSError *error) {
                statusOne = status;
                errorOne = error;
                done();
            }];
        });

        waitUntil(^(DoneCallback done){
            [resultTwo cmh_saveToStudyWithDescriptor:@"StepTwoDescriptor" withCompletion:^(NSString *status, NSError *error) {
                statusTwo = status;
                errorTwo = error;
                done();
            }];
        });

        expect(errorOne).to.beNil();
        expect(statusOne).to.equal(@"created");

        expect(errorTwo).to.beNil();
        expect(statusTwo).to.equal(@"created");
    });

    it(@"should pass", ^{
        expect(YES).to.beTruthy();
    });
});

SpecEnd

