#import <CloudMine/CloudMine.h>
#import "CMHUser.h"

@class CMHUserData;
@class CMHRegistrationData;

@interface CMHInternalUser : CMUser

+ (void)signupWithRegistration:(CMHRegistrationData *)regData andCompletion:(CMHUserAuthCompletion)block;
+ (void)loginAndLoadProfileWithEmail:(NSString *)email password:(NSString *)password andCompletion:(CMHUserAuthCompletion)block;

- (void)loadProfileWithCompletion:(CMHUserAuthCompletion)block;
- (void)updateProfileWithUserData:(CMHUserData *)userData withCompletion:(void(^)(NSError *error))block;
- (CMHUserData *)generateCurrentUserData;

@property (nonatomic) NSString *profileId;
@property (nonatomic, readonly) BOOL hasName;

@end
