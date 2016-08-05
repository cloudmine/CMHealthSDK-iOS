#import <CloudMine/CloudMine.h>
#import "CMHUser.h"

@class CMHUserData;
@class CMHRegistrationData;

@interface CMHInternalUser : CMUser

+ (void)signupWithRegistration:(CMHRegistrationData *)regData andCompletion:(CMHUserAuthCompletion)block;
+ (void)loginAndLoadProfileWithEmail:(NSString *)email password:(NSString *)password andCompletion:(CMHUserAuthCompletion)block;

- (void)loadProfileWithCompletion:(CMHUserAuthCompletion)block;
- (void)updateFamilyName:(NSString *)familyName givenName:(NSString *)givenName withCompletion:(CMHUserAuthCompletion)block;
- (CMHUserData *)generateCurrentUserData;

@property (nonatomic) NSString *profileId;
@property (nonatomic, readonly) BOOL hasName;

@end
