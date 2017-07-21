#import "CMHInternalUser.h"
#import "CMHUserData_internal.h"
#import "CMHInternalProfile.h"
#import "CMHRegistrationData.h"
#import "CMHErrorUtilities.h"
#import "CMHConfiguration.h"
#import "CMHCareObjectSaver.h"
#import "CMHCareFileMetadata.h"

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
    newUser.profile.isAdmin = NO;
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
    self.profile.isAdmin = userData.isAdmin;
    self.profile.givenName = userData.givenName;
    self.profile.familyName = userData.familyName;
    self.profile.gender = userData.gender;
    self.profile.dateOfBirth = userData.dateOfBirth;
    self.profile.userInfo = userData.userInfo;
    
    [CMHInternalUser saveUserProfile:self.profile completion:^(NSError * _Nullable error) {
        block(error);
    }];
}

- (void)uploadProfileImage:(UIImage *)image withCompletion:(CMHUploadProfileImageCompletion)block
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    
    if (nil == imageData) {
        if (nil != block) {
            block(NO, nil); // TODO: send a custom error?
        }
        return;
    }
    
    [[CMStore defaultStore] saveUserFileWithData:imageData additionalOptions:nil callback:^(CMFileUploadResponse *response) {
        if (nil != response.error) {
            if (nil != block) {
                block(NO, response.error);
            }
            return;
        }
        
        if (!(CMFileCreated == response.result || CMFileUpdated == response.result) || nil == response.key) {
            if (nil != block) {
                block(NO, nil); // TODO: send a custom error?
            }
            return;
        }
        
        self.profile.photoId = response.key;
        
        [CMHInternalUser shareProfilePhotoWithId:self.profile.photoId completion:^(NSError * _Nullable shareError) {
            if (nil != shareError) {
                if (nil != block) {
                    block(NO, shareError);
                }
                return;
            }
            
            [CMHInternalUser saveUserProfile:self.profile completion:^(NSError * _Nullable saveError) {
                if (nil != block) {
                    BOOL success = nil == saveError;
                    block(success, saveError);
                }
            }];
        }];
    }];
}

- (void)fetchProfileImageWithCompletion:(CMHFetchProfileImageCompletion)block
{
    if (nil == self.profile.photoId) {
        if (nil != block) {
            block(YES, nil, nil);
        }
        
        return;
    }
    
    [[CMStore defaultStore] userFileWithName:self.profile.photoId additionalOptions:nil callback:^(CMFileFetchResponse *response) {
        if (nil != response.error) {
            if (nil != block) {
                block(NO, nil, response.error);
            }
            return;
        }
        
        if (nil == response.file.fileData) {
            if (nil != block) {
                block(YES, nil, nil);
            }
            return;
        }
        
        UIImage *profileImage = [UIImage imageWithData:response.file.fileData];
        
        if (nil != block) {
            block(YES, profileImage, nil);
        }
    }];
}

- (CMHUserData *)generateCurrentUserData
{
    return [[CMHUserData alloc] initWithInternalProfile:self.profile userId:self.objectId];
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

+ (void)shareProfilePhotoWithId:(nonnull NSString *)photoId completion:(void (^_Nonnull)(NSError *_Nullable error))block
{
    if (![CMHConfiguration sharedConfiguration].shouldShareUserProfile) {
        block(nil);
        return;
    }
    
    CMHCareFileMetadata *metadata = [[CMHCareFileMetadata alloc] initWithObjectId:photoId];
    metadata.cmhOwnerId = [CMHInternalUser currentUser].objectId;
    
    [CMHCareObjectSaver saveCMHCareObject:metadata withCompletion:^(NSString * _Nullable status, NSError * _Nullable error) {
        block(error);
    }];
}

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
