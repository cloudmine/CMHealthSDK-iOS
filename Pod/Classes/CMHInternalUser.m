#import "CMHInternalUser.h"
#import "CMHInternalProfile.h"
#import "CMHErrorUtilities.h"
#import "CMHUserData_internal.h"

@interface CMHInternalUser ()
@property (nonatomic, nullable) CMHInternalProfile *profile;
@end

@implementation CMHInternalUser

+ (instancetype)currentUser
{
    return [super currentUser];
}

#pragma mark Public

- (void)signUpWithEmail:(NSString *)email password:(NSString *)password andCompletion:(CMHUserAuthCompletion)block
{
    self.profile = [CMHInternalProfile new];
    self.profile.email = email;
    self.profileId = self.profile.objectId;

    [self createAccountWithCallback:^(CMUserAccountResult createResultCode, NSArray *messages) {
        NSError *createError = [CMHErrorUtilities errorForAccountResult:createResultCode];
        if (nil != createError) {
            if (nil != block) {
                block(createError);
            }
            return;
        }

        [self loginWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
            NSError *loginError = [CMHErrorUtilities errorForAccountResult:resultCode];
            if (nil != loginError) {
                if (nil != block) {
                    block(loginError);
                }
                return;
            }

            [CMStore.defaultStore saveUserObject:self.profile callback:^(CMObjectUploadResponse *response) {
                NSError *saveError = [CMHErrorUtilities errorForKind:@"user profile" objectId:self.profile.objectId uploadResponse:response];
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

        [CMStore.defaultStore userObjectsWithKeys:@[user.profileId] additionalOptions:nil callback:^(CMObjectFetchResponse *response) {
            NSError *profileError = [CMHErrorUtilities errorForKind:@"profile" fetchResponse:response];
            if (nil != profileError) {
                if (nil != block) {
                    block(profileError);
                }
                return;
            }

            user.profile = response.objects.firstObject;

            if (nil != block) {
                block(nil);
            }
        }];
    }];
}

- (void)updateFamilyName:(NSString *)familyName givenName:(NSString *)givenName withCompletion:(CMHUserAuthCompletion)block
{
    self.profile.familyName = familyName;
    self.profile.givenName = givenName;

    [self.profile save:^(CMObjectUploadResponse *response) {
        NSError *saveError = [CMHErrorUtilities errorForKind:@"user profile" objectId:self.profile.objectId uploadResponse:response];
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

    self.givenName = [aDecoder decodeObjectForKey:@"givenName"];
    self.familyName = [aDecoder decodeObjectForKey:@"familyName"];
    self.profileId = [aDecoder decodeObjectForKey:@"profileId"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];

    if (nil != self.givenName) {
        [aCoder encodeObject:self.givenName forKey:@"givenName"];
    }

    if (nil != self.familyName) {
        [aCoder encodeObject:self.familyName forKey:@"familyName"];
    }

    if (nil != self.profileId) {
        [aCoder encodeObject:self.profileId forKey:@"profileId"];
    }
}

@end
