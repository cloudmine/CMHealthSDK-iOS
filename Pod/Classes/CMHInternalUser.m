#import "CMHInternalUser.h"
#import "CMHUserData_internal.h"
#import "CMHInternalProfile.h"
#import "CMHRegistrationData.h"
#import "CMHErrorUtilities.h"
#import "CMHConfiguration.h"
#import "CMHCareObjectSaver.h"

@interface CMHInternalUser ()
@property (nonatomic, nullable) CMHInternalProfile *profile;
@end

@implementation CMHInternalUser

+ (instancetype)currentUser
{
    return [super currentUser];
}

#pragma mark Public

+ (void)signupWithRegistration:(CMHRegistrationData *)regData andCompletion:(CMHUserAuthCompletion)block
{
    CMHInternalUser *newUser = [[CMHInternalUser alloc] initWithEmail:regData.email andPassword:regData.password];
    newUser.profile = [CMHInternalProfile new];
    newUser.profile.email = regData.email;
    newUser.profileId = newUser.profile.objectId;
    newUser.profile.familyName = regData.familyName;
    newUser.profile.givenName = regData.givenName;
    newUser.profile.gender = regData.gender;
    newUser.profile.dateOfBirth = regData.birthdate;

    [CMStore defaultStore].user = newUser;

    [newUser createAccountWithCallback:^(CMUserAccountResult createResultCode, NSArray *messages) {
        NSError *createError = [CMHErrorUtilities errorForAccountResult:createResultCode];
        if (nil != createError) {
            if (nil != block) {
                block(createError);
            }
            return;
        }

        [newUser loginWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
            NSError *loginError = [CMHErrorUtilities errorForAccountResult:resultCode];
            if (nil != loginError) {
                if (nil != block) {
                    block(loginError);
                }
                return;
            }

            newUser.profile.cmhOwnerId = [CMHInternalUser currentUser].objectId;

            [self saveUserProfile:newUser.profile completion:^(NSError * _Nullable saveError) {
                if (nil != saveError) {
                    if (nil != block) {
                        block(saveError);
                    }
                    return;
                }

                if (nil != block) {
                    block(nil);
                }
            }];
        }];
    }];
}

+ (void)loginAndLoadProfileWithEmail:(NSString *)email password:(NSString *)password andCompletion:(CMHUserAuthCompletion)block
{
    CMHInternalUser *user = [[CMHInternalUser alloc] initWithEmail:email andPassword:password];
    [CMStore defaultStore].user = user;

    [user loginWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
        NSError *loginError = [CMHErrorUtilities errorForAccountResult:resultCode];
        if (nil != loginError) {
            if (nil != block) {
                block(loginError);
            }
            return;
        }

        [user loadProfileWithCompletion:block];
    }];
}

- (void)loadProfileWithCompletion:(CMHUserAuthCompletion)block
{
    NSAssert(self.isLoggedIn, @"Cannot load profile of logged out user");

    [CMStore.defaultStore userObjectsWithKeys:@[self.profileId] additionalOptions:nil callback:^(CMObjectFetchResponse *response) {
        NSError *profileError = [CMHErrorUtilities errorForKind:@"profile" fetchResponse:response];
        if (nil != profileError) {
            if (nil != block) {
                block(profileError);
            }
            return;
        }

        // State of the user may have changed request was initiated
        if (self.isLoggedIn) {
            self.profile = response.objects.firstObject;
        }

        if (nil != block) {
            block(nil);
        }
    }];
}

- (void)updateProfileWithUserData:(CMHUserData *)userData withCompletion:(void(^)(NSError *error))block;
{
    self.profile.email = userData.email;
    self.profile.givenName = userData.givenName;
    self.profile.familyName = userData.familyName;
    self.profile.gender = userData.gender;
    self.profile.dateOfBirth = userData.dateOfBirth;
    self.profile.userInfo = userData.userInfo;
    
    [CMHInternalUser saveUserProfile:self.profile completion:^(NSError * _Nullable error) {
        block(error);
    }];
}

- (CMHUserData *)generateCurrentUserData
{
    return [[CMHUserData alloc] initWithInternalProfile:self.profile];
}

- (BOOL)hasName
{
    return !(nil == self.profile.familyName || [@"" isEqualToString:self.profile.familyName] || nil == self.profile.givenName || [@"" isEqualToString:self.profile.givenName]);
}

# pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    self.profileId = [aDecoder decodeObjectForKey:@"profileId"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];

    if (nil != self.profileId) {
        [aCoder encodeObject:self.profileId forKey:@"profileId"];
    }
}

#pragma mark Private Helpers

+ (void)saveUserProfile:(nonnull CMHInternalProfile *)profile completion:(void (^_Nonnull)(NSError *_Nullable error))block
{
    if ([CMHConfiguration sharedConfiguration].shouldShareUserProfile) {
        [CMHCareObjectSaver saveCMHCareObject:profile withCompletion:^(NSString * _Nullable status, NSError * _Nullable sharedSaveError) {
            block(sharedSaveError);
        }];
    } else {
        [CMStore.defaultStore saveUserObject:profile callback:^(CMObjectUploadResponse *response) {
            NSError *saveError = [CMHErrorUtilities errorForKind:@"user profile" objectId:profile.objectId uploadResponse:response];
            block(saveError);
        }];
    }
}

@end
