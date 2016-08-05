#import <CMHealth/CMHealth.h>
#import <CMHealth/CMHRegistrationData.h>

SpecBegin(CMHRegistrationData)

describe(@"CMHRegistrationData", ^{
    it(@"should retain the user's email and password", ^{
        CMHRegistrationData *regData = [[CMHRegistrationData alloc] initWithEmail:@"test@test.com"
                                                                         password:@"testpassword123"
                                                                           gender:nil
                                                                        birthdate:nil
                                                                        givenName:nil
                                                                       familyName:nil];

        expect(regData).notTo.beNil();
        expect(regData.email).to.equal(@"test@test.com");
        expect(regData.password).to.equal(@"testpassword123");
    });

    it(@"should retain all the user's registration data", ^{
        NSDate *dob = [NSDate new];
        CMHRegistrationData *regData = [[CMHRegistrationData alloc] initWithEmail:@"test@test.com"
                                                                         password:@"testpassword123"
                                                                           gender:@"female"
                                                                        birthdate:dob
                                                                        givenName:@"Jane"
                                                                       familyName:@"Doe"];
        expect(regData).notTo.beNil();
        expect(regData.email).to.equal(@"test@test.com");
        expect(regData.password).to.equal(@"testpassword123");
        expect(regData.gender).to.equal(@"female");
        expect(regData.birthdate).to.equal(dob);
        expect(regData.givenName).to.equal(@"Jane");
        expect(regData.familyName).to.equal(@"Doe");
    });

    it(@"should return nil for a registration result without an email", ^{
        ORKTextQuestionResult *passwordResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierPassword];
        passwordResult.textAnswer = @"testpassword123";

        ORKCollectionResult *regResult = [[ORKCollectionResult alloc] initWithIdentifier:@"CMHRegistrationTestResult"];
        regResult.results = @[passwordResult];

        CMHRegistrationData *regData = [CMHRegistrationData registrationDataFromResult:regResult];

        expect(regData).to.beNil();
    });

    it(@"should return nil for a registration result without a password", ^{
        ORKTextQuestionResult *emailResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierEmail];
        emailResult.textAnswer = @"test@test.com";

        ORKCollectionResult *regResult = [[ORKCollectionResult alloc] initWithIdentifier:@"CMHRegistrationTestResult"];
        regResult.results = @[emailResult];

        CMHRegistrationData *regData = [CMHRegistrationData registrationDataFromResult:regResult];

        expect(regData).to.beNil();
    });

    it(@"should extract the user's email and password from registration results", ^{
        ORKTextQuestionResult *emailResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierEmail];
        emailResult.textAnswer = @"test@test.com";

        ORKTextQuestionResult *passwordResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierPassword];
        passwordResult.textAnswer = @"testpassword123";

        ORKCollectionResult *regResult = [[ORKCollectionResult alloc] initWithIdentifier:@"CMHRegistrationTestResult1"];
        regResult.results = @[emailResult, passwordResult];

        CMHRegistrationData *regData = [CMHRegistrationData registrationDataFromResult:regResult];

        expect(regData).notTo.beNil();
        expect(regData.email).to.equal(@"test@test.com");
        expect(regData.password).to.equal(@"testpassword123");
    });

    it(@"should extract all the user's registration data", ^{
        NSDate *dob = [NSDate new];

        ORKTextQuestionResult *emailResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierEmail];
        emailResult.textAnswer = @"test@test.com";

        ORKTextQuestionResult *passwordResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierPassword];
        passwordResult.textAnswer = @"testpassword123";

        ORKChoiceQuestionResult *genderResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierGender];
        genderResult.choiceAnswers = @[@"female"];

        ORKDateQuestionResult *dobResult = [[ORKDateQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierDOB];
        dobResult.dateAnswer = [dob copy];

        ORKTextQuestionResult *givenNameResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierGivenName];
        givenNameResult.textAnswer = @"Jane";

        ORKTextQuestionResult *familyNameResult = [[ORKTextQuestionResult alloc] initWithIdentifier:ORKRegistrationFormItemIdentifierFamilyName];
        familyNameResult.textAnswer = @"Doe";

        ORKCollectionResult *regResult = [[ORKCollectionResult alloc] initWithIdentifier:@"CMHRegistrationTestResult2"];
        regResult.results = @[emailResult, passwordResult, genderResult, dobResult, givenNameResult, familyNameResult];

        CMHRegistrationData *regData = [CMHRegistrationData registrationDataFromResult:regResult];

        expect(regData).notTo.beNil();
        expect(regData.email).to.equal(@"test@test.com");
        expect(regData.password).to.equal(@"testpassword123");
        expect(regData.gender).to.equal(@"female");
        expect(regData.birthdate).to.equal(dob);
        expect(regData.givenName).to.equal(@"Jane");
        expect(regData.familyName).to.equal(@"Doe");
    });

});

SpecEnd