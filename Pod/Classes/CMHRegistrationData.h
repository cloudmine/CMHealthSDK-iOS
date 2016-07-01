#import <ResearchKit/ResearchKit.h>

@interface CMHRegistrationData : NSObject

@property (nonatomic, nonnull,  readonly) NSString *email;
@property (nonatomic, nonnull,  readonly) NSString *password;
@property (nonatomic, nullable, readonly) NSString *gender;
@property (nonatomic, nullable, readonly) NSDate   *birthdate;
@property (nonatomic, nullable, readonly) NSString *givenName;
@property (nonatomic, nullable, readonly) NSString *familyName;

- (_Nonnull instancetype)initWithEmail:(NSString *_Nonnull)email
                              password:(NSString *_Nonnull)password
                                gender:(NSString *_Nullable)gender
                             birthdate:(NSDate *_Nullable)birthdate
                             givenName:(NSString *_Nullable)givenName
                            familyName:(NSString *_Nullable)familyName;

+ (_Nullable instancetype)registrationDataFromResult:(ORKCollectionResult *_Nullable)result;

@end
