#import "CMHRegistrationData.h"

@interface CMHRegistrationData ()
@property (nonatomic, nonnull,  readwrite) NSString *email;
@property (nonatomic, nonnull,  readwrite) NSString *password;
@property (nonatomic, nullable, readwrite) NSString *gender;
@property (nonatomic, nullable, readwrite) NSDate   *birthdate;
@property (nonatomic, nullable, readwrite) NSString *givenName;
@property (nonatomic, nullable, readwrite) NSString *familyName;
@end

@implementation CMHRegistrationData

- (_Nonnull instancetype)initWithEmail:(NSString *_Nonnull)email
                              password:(NSString *_Nonnull)password
                                gender:(NSString *_Nullable)gender
                             birthdate:(NSDate *_Nullable)birthdate
                             givenName:(NSString *_Nullable)givenName
                            familyName:(NSString *_Nullable)familyName
{
    self = [super init];
    if (nil == self || nil == email || nil == password) return nil;

    self.email = email;
    self.password = password;
    self.gender = gender;
    self.birthdate = birthdate;
    self.givenName = givenName;
    self.familyName = familyName;

    return self;
}

+ (_Nullable instancetype)registrationDataFromResult:(ORKCollectionResult *_Nullable)result
{
    if (nil == result) {
        return nil;
    }

    NSString *email = ((ORKTextQuestionResult *)[result resultForIdentifier:ORKRegistrationFormItemIdentifierEmail]).textAnswer;
    NSString *password = ((ORKTextQuestionResult *)[result resultForIdentifier:ORKRegistrationFormItemIdentifierPassword]).textAnswer;
    NSString *gender = ((ORKChoiceQuestionResult *)[result resultForIdentifier:ORKRegistrationFormItemIdentifierGender]).choiceAnswers.firstObject;
    NSDate *birthdate = ((ORKDateQuestionResult *)[result resultForIdentifier:ORKRegistrationFormItemIdentifierDOB]).dateAnswer;
    NSString *givenName = ((ORKTextQuestionResult *)[result resultForIdentifier:ORKRegistrationFormItemIdentifierGivenName]).textAnswer;
    NSString *familyName = ((ORKTextQuestionResult *)[result resultForIdentifier:ORKRegistrationFormItemIdentifierFamilyName]).textAnswer;

    if (nil == email || nil == password) {
        return nil;
    }

    return [[CMHRegistrationData alloc] initWithEmail:email
                                             password:password
                                               gender:gender
                                            birthdate:birthdate
                                            givenName:givenName
                                           familyName:familyName];
}

@end
