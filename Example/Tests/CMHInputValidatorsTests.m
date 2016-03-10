#import <Foundation/Foundation.h>
#import <CMHealth/CMHInputValidators.h>

SpecBegin(CMHealthInputValidators)

describe(@"CMHInputValidators", ^{
    it(@"should return an error message for a nil email", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:nil];
        expect(errorMessage).notTo.beNil();
    });

    it(@"should return an error message for an empty email", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@""];
        expect(errorMessage).notTo.beNil();
    });

    it(@"should return an error message for an email that doesn't have an @", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@"test#test.com"];
        expect(errorMessage).notTo.beNil();
    });

    pending(@"should return an error message for an email that has two @'s'", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@"t@est@test.com"];
        expect(errorMessage).notTo.beNil();
    });

    it(@"should return an error message for an email that doesn't have a TLD", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@"te.st@testcom"];
        expect(errorMessage).notTo.beNil();
    });

    it(@"should return an error message for an email that doesn't have a name", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@"@test.com"];
        expect(errorMessage).notTo.beNil();
    });

    it(@"should return an error message for an email that ends in a dot without a TLD", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@"test@test."];
        expect(errorMessage).notTo.beNil();
    });

    it(@"should return an error message for an email that ends in a dot after the TLD", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@"test@test.com."];
        expect(errorMessage).notTo.beNil();
    });

    it(@"should return an error message for an email thats missing the domain", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@"test@"];
        expect(errorMessage).notTo.beNil();
    });

    it(@"should return nil for a valid email", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@"test@test.com"];
        expect(errorMessage).to.beNil();
    });

    it(@"should return a nil for a valid email with a dot in the name", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@"te.st@test.com"];
        expect(errorMessage).to.beNil();
    });

    it(@"should return a nil for a valid email with a dot in the domain", ^{
        NSString *errorMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:@"test@test.co.uk"];
        expect(errorMessage).to.beNil();
    });
});

SpecEnd
