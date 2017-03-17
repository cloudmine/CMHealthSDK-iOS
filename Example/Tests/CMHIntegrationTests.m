#import <CMHealth/CMHealth.h>
#import "CMHTest-Secrets.h"
#import "CMHTestCleaner.h"
#import "CMHWrapperTestFactory.h"

static NSString *const TestDescriptor = @"CMHTestDescriptor";
static NSString *const TestPassword   = @"test-paSsword1!";
static NSString *const TestGivenName  = @"John";
static NSString *const TestFamilyName = @"Doe";

@interface CMHIntegrationTestFactory : NSObject
+ (ORKTaskResult *)registrationTaskResultWithEmail:(NSString *)emailAddress;
@end

@implementation CMHIntegrationTestFactory

+ (NSString *)genderString
{
    return @"female";
}

+ (NSString *)updateGenderString
{
    return @"male";
}

+ (NSDate *)dateOfBirth
{
    return [NSDate dateWithTimeIntervalSince1970:30000];
}

+ (NSDate *)updateDateOfBirth
{
    return [NSDate dateWithTimeIntervalSince1970:116000];
}

+ (NSDictionary *)updateUserInfo
{
    return @{ @"key1" : @"A String element",
              @"key2" : @YES,
              @"key3" : @116,
              @"key4" : @[@"Hello", @"World"] };
}

+ (ORKCollectionResult *)registrationResultWithEmail:(NSString *)emailAddress
{
    ORKTextQuestionResult *emailResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierEmail];
    emailResult.textAnswer = emailAddress;

    ORKTextQuestionResult *passwordResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierPassword];
    passwordResult.textAnswer = TestPassword;

    ORKChoiceQuestionResult *genderResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierGender];
    genderResult.choiceAnswers = @[self.genderString];

    ORKDateQuestionResult *dobResult = [[ORKDateQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierDOB];
    dobResult.dateAnswer = self.dateOfBirth;

    ORKCollectionResult *regResult = [[ORKCollectionResult alloc] initWithIdentifier:@"CMHRegistrationTestResult"];
    regResult.results = @[emailResult, passwordResult, genderResult, dobResult];

    return regResult;
}

+ (ORKTaskResult *)registrationTaskResultWithEmail:(NSString *)emailAddress
{
    ORKTaskResult *topResult = [[ORKTaskResult alloc] initWithIdentifier:@"CMHTestIdentifier"];
    ORKTaskResult *firstResult = [[ORKTaskResult alloc] initWithIdentifier:@"CMHTestIdentifier1"];
    ORKTaskResult *secondResult = [[ORKTaskResult alloc] initWithIdentifier:@"CMHTestIdentifier2"];
    ORKStepResult *finalResult = [[ORKStepResult alloc] initWithStepIdentifier:@"CMHTestStepIdentifier" results:nil];

    finalResult.results = @[ORKTextQuestionResult.new, [self registrationResultWithEmail:emailAddress], ORKTextQuestionResult.new];
    secondResult.results = @[finalResult];
    topResult.results = @[firstResult, secondResult];

    return topResult;
}

@end

SpecBegin(CMHealthIntegration)

describe(@"CMHealthIntegration", ^{
    __block CMHConsent *consentToClean = nil;

    beforeAll(^{
        NSString *assertionError = @"You haven't set valid credentials in CMHTest-Secrets.h";
        NSAssert(CMHTestsAppId.length > 0, assertionError);
        NSAssert(![CMHTestsAppId isEqualToString:@"REPLACE_WITH_AN_APP_ID_TO_USE_FOR_TESTING"], assertionError);
        NSAssert(CMHTestsAPIKey.length > 0, assertionError);
        NSAssert(![CMHTestsAPIKey isEqualToString:@"REPLACE_WITH_API_KEY"], assertionError);
        NSAssert(CMHTestsAsyncTimeout >= 1.0, @"An async timeout of less than 1 second is not advised; tests will run as fast as your connection allows regardless of the timeout value; lowering the value will not speed up test time and can lead to false failures.");
        NSAssert([[ORKLocation alloc] respondsToSelector:@selector(initWithCoordinate:region:userInput:addressDictionary:)], @"Private API of ORKLocation, exposed for testing, has changed");


        [CMHealth setAppIdentifier:CMHTestsAppId appSecret:CMHTestsAPIKey];
        setAsyncSpecTimeout(CMHTestsAsyncTimeout);

        waitUntil(^(DoneCallback done) {
            if([CMHUser currentUser].isLoggedIn) {
                [[CMHUser currentUser] logoutWithCompletion:^(NSError *error){
                    done();
                }];
            } else {
                done();
            }
        });

        NSAssert(![CMHUser currentUser].isLoggedIn, @"Failed to log user out before beginning test");
    });

    it(@"should create a user and sign them up", ^{
        NSString *unixTime = [NSNumber numberWithInt:(int)[NSDate new].timeIntervalSince1970].stringValue;
        NSString *emailAddress = [NSString stringWithFormat:@"cmhealth+%@@cloudmineinc.com", unixTime];

        ORKTaskResult *regResult = [CMHIntegrationTestFactory registrationTaskResultWithEmail:emailAddress];

        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] signUpWithRegistration:regResult andCompletion:^(NSError *error) {
                done();
            }];
        });

        expect([CMHUser currentUser].isLoggedIn).to.equal(YES);
        expect([CMHUser currentUser].userData.email).to.equal(emailAddress);
        expect([CMHUser currentUser].userData.gender).to.equal(CMHIntegrationTestFactory.genderString);
        expect([CMHUser currentUser].userData.dateOfBirth).to.equal(CMHIntegrationTestFactory.dateOfBirth);
        expect([CMHUser currentUser].userData.userInfo).to.equal(@{});
    });

    it(@"should upload a user consent and consent PDF", ^{
        ORKTaskResult *consentResult = [[ORKTaskResult alloc] initWithTaskIdentifier:@"CMHTestIdentifier" taskRunUUID:[NSUUID new] outputDirectory:nil];
        ORKConsentSignatureResult *signatureResult = [ORKConsentSignatureResult new];
        signatureResult.consented = YES;
        signatureResult.signature = [ORKConsentSignature signatureForPersonWithTitle:nil
                                                                    dateFormatString:nil
                                                                    identifier:@"CMHTestIdentifier"
                                                                           givenName:TestGivenName
                                                                          familyName:TestFamilyName
                                                                      signatureImage:[UIImage imageNamed:@"Test-Signature-Image.png"]
                                                                          dateString:nil];
        consentResult.results = @[signatureResult];

        __block NSError *uploadError = nil;
        __block CMHConsent *returnConsent = nil;

        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] uploadUserConsent:consentResult forStudyWithDescriptor:TestDescriptor andCompletion:^(CMHConsent *consent, NSError *error) {
                uploadError = error;
                returnConsent = consent;
                done();
            }];
        });

        consentToClean = returnConsent;

        expect(uploadError).to.beNil();
        expect(returnConsent.consentResult).to.equal(consentResult);
        expect([CMHUser currentUser].userData.familyName).to.equal(TestFamilyName);
        expect([CMHUser currentUser].userData.givenName).to.equal(TestGivenName);

        __block NSError *pdfUploadError = nil;

        NSString *pdfPath = [NSBundle.mainBundle pathForResource:@"Test-Consent-PDF" ofType:@"pdf"];
        NSURL *pdfURL = [NSURL fileURLWithPath:pdfPath];
        NSData *pdfData = [[NSData alloc] initWithContentsOfURL:pdfURL];

        waitUntil(^(DoneCallback done) {
            [returnConsent uploadConsentPDF:pdfData withCompletion:^(NSError *error) {
                pdfUploadError = error;
                done();
            }];
        });

        expect(pdfUploadError).to.beNil();
    });

    it(@"should fetch a user's consent, signature image, and PDF", ^{
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

        __block NSData *pdfData = nil;
        __block NSError *pdfError = nil;


        waitUntil(^(DoneCallback done) {
            [fetchedConsent fetchConsentPDFWithCompletion:^(NSData *data, NSError *error) {
                pdfData = data;
                pdfError = error;
                done();
            }];
        });

        NSString *localPDFPath = [NSBundle.mainBundle pathForResource:@"Test-Consent-PDF" ofType:@"pdf"];
        NSURL *localPDFURL = [NSURL fileURLWithPath:localPDFPath];
        NSData *localPDFData = [[NSData alloc] initWithContentsOfURL:localPDFURL];

        expect(pdfError).to.beNil();
        expect(pdfData).to.equal(localPDFData);
    });
    
    it(@"should let us update the user's profile data", ^{
        __block CMHUserData *updateUserData = nil;
        __block NSError *updateError = nil;
        
        CMHMutableUserData *mutableUserData = [[CMHUser currentUser].userData mutableCopy];
        mutableUserData.gender = CMHIntegrationTestFactory.updateGenderString;
        mutableUserData.dateOfBirth = CMHIntegrationTestFactory.updateDateOfBirth;
        mutableUserData.userInfo = CMHIntegrationTestFactory.updateUserInfo;
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] updateUserData:mutableUserData withCompletion:^(CMHUserData * _Nullable userData, NSError * _Nullable error) {
                updateUserData = userData;
                updateError = error;
                done();
            }];
        });
        
        expect(updateError).to.beNil();
        expect(updateUserData == [CMHUser currentUser].userData).to.beTruthy();
        expect(updateUserData.gender).to.equal(CMHIntegrationTestFactory.updateGenderString);
        expect(updateUserData.dateOfBirth).to.equal(CMHIntegrationTestFactory.updateDateOfBirth);
        expect(updateUserData.userInfo).to.equal(CMHIntegrationTestFactory.updateUserInfo);
        expect([CMHUser currentUser].userData.familyName).to.equal(TestFamilyName);
        expect([CMHUser currentUser].userData.givenName).to.equal(TestGivenName);
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
        // ORKScaleQuestionResult

        ORKScaleQuestionResult *scaleResult = [ORKScaleQuestionResult new];
        scaleResult.scaleAnswer = [NSNumber numberWithDouble:1.16];

        // ORKBooleanQuestionResult

        ORKBooleanQuestionResult *booleanResult = [ORKBooleanQuestionResult new];
        booleanResult.booleanAnswer = [NSNumber numberWithBool:YES];

        // ORKDateQuestionResult

        ORKDateQuestionResult *dateResult = [ORKDateQuestionResult new];
        dateResult.dateAnswer = [NSDate dateWithTimeIntervalSince1970:127.0];
        dateResult.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierChinese];
        dateResult.timeZone = [NSTimeZone timeZoneWithName:@"Pacific/Honolulu"];

        // ORKTimeOfDayQuestionResult

        ORKTimeOfDayQuestionResult *timeResult = [ORKTimeOfDayQuestionResult new];
        timeResult.dateComponentsAnswer = [CMHWrapperTestFactory testDateComponents];

        // ORKChoiceQuestionResult

        ORKChoiceQuestionResult *choiceResult = [ORKChoiceQuestionResult new];
        choiceResult.choiceAnswers = @[@"Hello", @"Wide", @"World"];

        // ORKTextQuestionResult

        ORKTextQuestionResult *textResult = [ORKTextQuestionResult new];
        textResult.textAnswer = @"The quick brown fox jumped over the lazy dog.";

        // ORKNumericQuestionResult

        ORKNumericQuestionResult *numericResult = [ORKNumericQuestionResult new];
        numericResult.numericAnswer = @11.6;

        // ORKTimeIntervalQuestionResult

        ORKTimeIntervalQuestionResult *intervalResult = [ORKTimeIntervalQuestionResult new];
        intervalResult.intervalAnswer = @8.27;

        // ORKLocationQuestionResult

        ORKLocationQuestionResult *locationResult = [ORKLocationQuestionResult new];
        locationResult.locationAnswer = [CMHWrapperTestFactory location];

        taskResult.results = @[scaleResult, booleanResult, dateResult,
                               timeResult, choiceResult, textResult,
                               numericResult, intervalResult, locationResult];

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

        // ORKScaleQuestionResult

        expect([task.results[0] class]).to.equal([ORKScaleQuestionResult class]);
        expect(((ORKScaleQuestionResult *)task.results[0]).scaleAnswer.doubleValue).to.equal(1.16);

        // ORKBooleanQuestionResult

        expect([task.results[1] class]).to.equal([ORKBooleanQuestionResult class]);
        expect(((ORKBooleanQuestionResult *)task.results[1]).booleanAnswer.boolValue).to.equal(YES);

        // ORKDateQuestionResult

        expect([task.results[2] class]).to.equal([ORKDateQuestionResult class]);
        ORKDateQuestionResult *dateResult = (ORKDateQuestionResult *)task.results[2];
        expect(dateResult.dateAnswer.timeIntervalSince1970).to.equal(127.0);
        expect(dateResult.calendar).to.equal([NSCalendar calendarWithIdentifier:NSCalendarIdentifierChinese]);
        expect(dateResult.timeZone).to.equal([NSTimeZone timeZoneWithName:@"Pacific/Honolulu"]);

        // ORKTimeOfDateQuestionResult

        expect([task.results[3] class]).to.equal([ORKTimeOfDayQuestionResult class]);
        ORKTimeOfDayQuestionResult *timeResult = (ORKTimeOfDayQuestionResult *)task.results[3];
        expect([CMHWrapperTestFactory isEquivalentToTestDateComponents:timeResult.dateComponentsAnswer]).to.beTruthy();

        // ORKChoiceQuestionResult

        expect([task.results[4] class]).to.equal([ORKChoiceQuestionResult class]);
        NSArray<NSString *> *answers = ((ORKChoiceQuestionResult *)task.results[4]).choiceAnswers;
        expect(answers[0]).to.equal(@"Hello");
        expect(answers[1]).to.equal(@"Wide");
        expect(answers[2]).to.equal(@"World");

        // ORKTextQuestionResult

        expect([task.results[5] class]).to.equal([ORKTextQuestionResult class]);
        ORKTextQuestionResult *textResult = (ORKTextQuestionResult *)task.results[5];
        expect(textResult.textAnswer).to.equal(@"The quick brown fox jumped over the lazy dog.");

        // ORKNumericQuestionResult

        expect([task.results[6] class]).to.equal([ORKNumericQuestionResult class]);
        ORKNumericQuestionResult *numericResult = (ORKNumericQuestionResult *)task.results[6];
        expect(numericResult.numericAnswer).to.equal(@11.6);

        // ORKTimeIntervalQuestionResult

        expect([task.results[7] class]).to.equal([ORKTimeIntervalQuestionResult class]);
        ORKTimeIntervalQuestionResult *intervalResult = (ORKTimeIntervalQuestionResult *)task.results[7];
        expect(intervalResult.intervalAnswer).to.equal(@8.27);

        // ORKLocationQuestionResult

        expect([task.results[8] class]).to.equal([ORKLocationQuestionResult class]);
        ORKLocationQuestionResult *locationResult = (ORKLocationQuestionResult *)task.results[8];
        expect(locationResult.locationAnswer).to.equal([CMHWrapperTestFactory location]);
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

    it(@"should upload two task results and update one of them", ^{
        ORKTextQuestionResult *stepOneQuestionResult = [ORKTextQuestionResult new];
        stepOneQuestionResult.textAnswer = @"StepOne";
        ORKStepResult *stepResultOne = [[ORKStepResult alloc] initWithStepIdentifier:@"StepTestOneIdentifier" results:@[stepOneQuestionResult]];
        ORKTaskResult *taskResultOne = [[ORKTaskResult alloc] initWithTaskIdentifier:@"TaskTestOneIdentifier" taskRunUUID:[NSUUID UUID] outputDirectory:nil];
        taskResultOne.results = @[stepResultOne];

        ORKTextQuestionResult *stepTwoQuestionResult = [ORKTextQuestionResult new];
        stepTwoQuestionResult.textAnswer = @"StepTwo";
        ORKStepResult *stepResultTwo = [[ORKStepResult alloc] initWithStepIdentifier:@"StepTestTwoIdentifier" results:@[stepTwoQuestionResult]];
        ORKTaskResult *taskResultTwo = [[ORKTaskResult alloc] initWithTaskIdentifier:@"TaskTestTwoIdentifier" taskRunUUID:[NSUUID UUID] outputDirectory:nil];
        taskResultTwo.results = @[stepResultTwo];

        __block NSString *statusOne = nil;
        __block NSError *errorOne = nil;

        __block NSString *statusTwo = nil;
        __block NSError *errorTwo = nil;

        __block NSString *statusUpdate = nil;
        __block NSError *errorUpdate = nil;

        waitUntil(^(DoneCallback done){
            [taskResultOne cmh_saveToStudyWithDescriptor:TestDescriptor withCompletion:^(NSString *status, NSError *error) {
                statusOne = status;
                errorOne = error;
                done();
            }];
        });

        waitUntil(^(DoneCallback done){
            [taskResultTwo cmh_saveToStudyWithDescriptor:TestDescriptor withCompletion:^(NSString *status, NSError *error) {
                statusTwo = status;
                errorTwo = error;
                done();
            }];
        });

        ORKTextQuestionResult *updatedQuestionResult = [ORKTextQuestionResult new];
        updatedQuestionResult.textAnswer = @"StepTwoUpdated";
        ORKStepResult *updatedStepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"StepTestTwoIdentifier" results:@[updatedQuestionResult]];
        taskResultTwo.results = @[updatedStepResult];

        waitUntil(^(DoneCallback done) {
            [taskResultTwo cmh_saveToStudyWithDescriptor:TestDescriptor withCompletion:^(NSString *status, NSError *error) {
                statusUpdate = status;
                errorUpdate = error;
                done();
            }];
        });

        expect(errorOne).to.beNil();
        expect(statusOne).to.equal(@"created");

        expect(errorTwo).to.beNil();
        expect(statusTwo).to.equal(@"created");

        expect(errorUpdate).to.beNil();
        expect(statusUpdate).to.equal(@"updated");
    });

    it(@"should properly fetch uploaded results by their research kit identifier property", ^{
        __block NSArray *fetchResults = nil;
        __block NSError *fetchError = nil;

        waitUntil(^(DoneCallback done) {
            [ORKTaskResult cmh_fetchUserResultsForStudyWithDescriptor:TestDescriptor andIdentifier:@"TaskTestOneIdentifier" withCompletion:^(NSArray *results, NSError *error) {
                fetchResults = results;
                fetchError = error;
                done();
            }];
        });

        expect(fetchError).to.beNil();
        expect(fetchResults.count).to.equal(1);

        ORKTaskResult *taskResult = (ORKTaskResult *)fetchResults.firstObject;
        ORKTextQuestionResult *questionResult = (ORKTextQuestionResult *)((ORKStepResult *)taskResult.firstResult).firstResult;

        expect(questionResult.textAnswer).to.equal(@"StepOne");
    });

    it(@"should properly query uploaded results", ^{
        __block NSArray *fetchResults = nil;
        __block NSError *fetchError = nil;

        waitUntil(^(DoneCallback done) {
            [ORKTaskResult cmh_fetchUserResultsForStudyWithDescriptor:TestDescriptor andQuery:@"[identifier = \"TaskTestOneIdentifier\"]" withCompletion:^(NSArray *results, NSError *error) {
                fetchResults = results;
                fetchError = error;
                done();
            }];
        });

        expect(fetchError).to.beNil();
        expect(fetchResults.count).to.equal(1);

        ORKTaskResult *taskResult = (ORKTaskResult *)fetchResults.firstObject;
        ORKTextQuestionResult *questionResult = (ORKTextQuestionResult *)((ORKStepResult *)taskResult.firstResult).firstResult;

        expect(questionResult.textAnswer).to.equal(@"StepOne");
    });

    it(@"should properly fetch and update an existing result", ^{
        __block NSArray *firstFetchResults = nil;
        __block NSError *firstFetchError = nil;

        __block NSString *updateStatus = nil;
        __block NSError *updateError = nil;

        __block NSArray *secondFetchResults = nil;
        __block NSError *secondFetchError = nil;

        waitUntil(^(DoneCallback done) {
            [ORKTaskResult cmh_fetchUserResultsForStudyWithDescriptor:TestDescriptor andIdentifier:@"TaskTestTwoIdentifier" withCompletion:^(NSArray *results, NSError *error) {
                firstFetchResults = results;
                firstFetchError = error;
                done();
            }];
        });

        ORKTaskResult *firstTaskResult = (ORKTaskResult *)firstFetchResults.firstObject;
        ORKTextQuestionResult *questionResult = (ORKTextQuestionResult *)((ORKStepResult *)firstTaskResult.firstResult).firstResult;

        expect(firstFetchError).to.beNil();
        expect(firstFetchResults.count).to.equal(1);
        expect(questionResult.textAnswer).to.equal(@"StepTwoUpdated");

        ORKTextQuestionResult *updatedQuestionResult = [ORKTextQuestionResult new];
        updatedQuestionResult.textAnswer = @"UpdatedAgain";
        ORKStepResult *updatedStepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"StepTestTwoIdentifier" results:@[updatedQuestionResult]];
        firstTaskResult.results = @[updatedStepResult];

        waitUntil(^(DoneCallback done) {
            [firstTaskResult cmh_saveToStudyWithDescriptor:TestDescriptor withCompletion:^(NSString *status, NSError *error) {
                updateStatus = status;
                updateError = error;
                done();
            }];
        });

        expect(updateError).to.beNil();
        expect(updateStatus).to.equal(@"updated");

        waitUntil(^(DoneCallback done) {
            [ORKTaskResult cmh_fetchUserResultsWithRunUUID:firstTaskResult.taskRunUUID withCompletion:^(NSArray *results, NSError *error) {
                secondFetchResults = results;
                secondFetchError = error;
                done();
            }];
        });

        ORKTaskResult *secondTaskResult = (ORKTaskResult *)secondFetchResults.firstObject;

        expect(secondFetchError).to.beNil();
        expect(secondFetchResults.count).to.equal(1);
        expect(firstTaskResult == secondTaskResult).to.beFalsy();
        expect(secondTaskResult).to.equal(firstTaskResult);
        // expect(firstTaskResult).to.equal(secondTaskResult); // This fails due to a bug in the base SDK https://github.com/cloudmine/CloudMineSDK-iOS/issues/70
    });

    it(@"should log the user out and back in", ^{
        NSString *email = [CMHUser currentUser].userData.email;
        __block NSError *logoutError = nil;

        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] logoutWithCompletion:^(NSError *error) {
                logoutError = error;
                done();
            }];
        });

        expect(logoutError).to.beNil();
        expect([CMHUser currentUser].userData).to.beNil();
        expect([CMHUser currentUser].isLoggedIn).to.equal(NO);

        __block NSError *loginError = nil;

        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] loginWithEmail:email password:TestPassword andCompletion:^(NSError *error) {
                loginError = error;
                done();
            }];
        });

        expect(loginError).to.beNil();
        expect([CMHUser currentUser].isLoggedIn).to.beTruthy();
        expect([CMHUser currentUser].userData.email).to.equal(email);
        expect([CMHUser currentUser].userData.familyName).to.equal(TestFamilyName);
        expect([CMHUser currentUser].userData.givenName).to.equal(TestGivenName);
        expect([CMHUser currentUser].userData.gender).to.equal(CMHIntegrationTestFactory.updateGenderString);
        expect([CMHUser currentUser].userData.dateOfBirth).to.equal(CMHIntegrationTestFactory.updateDateOfBirth);
        expect([CMHUser currentUser].userData.userInfo).to.equal(CMHIntegrationTestFactory.updateUserInfo);
    });

    it(@"should pass", ^{
        expect(YES).to.beTruthy();
    });

    afterAll(^{
         waitUntil(^(DoneCallback done) {
             CMHTestCleaner *cleaner = [CMHTestCleaner new];
             [cleaner deleteConsent:consentToClean andResultsWithDescriptor:TestDescriptor withCompletion:^ {
                 done();
             }];
         });
    });
});

SpecEnd

