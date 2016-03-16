#import "CMHUser.h"
#import <CloudMine/CloudMine.h>
#import "CMHUserData.h"
#import "CMHUserData_internal.h"
#import "CMHInternalUser.h"
#import "ORKResult+CMHealth.h"
#import "CMHConsentValidator.h"
#import "CMHConsent_internal.h"
#import "CMHErrorUtilities.h"
#import "CMHConstants_internal.h"
#import "CMHInternalProfile.h"

@interface CMHUser ()
@property (nonatomic, nullable, readwrite) CMHUserData *userData;
@end

@implementation CMHUser

+ (instancetype)currentUser
{
    static CMHUser *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [CMHUser new];
        _sharedInstance.userData = [[CMHUserData alloc] initWithInternalUser:[CMHInternalUser currentUser]];

        // Need to think more carefully about this. It probably doesn't belong here, but I think
        // a goal should be to hide the sense of a "store" from the SDK consumer. We need to perform
        // this side effect somewhere, but where?
        [CMStore defaultStore].user = [CMHInternalUser currentUser];
    });

    return _sharedInstance;
}

- (void)signUpWithEmail:(NSString *)email password:(NSString *)password andCompletion:(CMHUserAuthCompletion)block
{
    self.userData = nil;
    CMHInternalUser *newUser = [[CMHInternalUser alloc] initWithEmail:email andPassword:password];
    [CMStore defaultStore].user = newUser;

    [newUser signUpWithEmail:email password:password andCompletion:^(NSError * _Nullable error) {
        self.userData = [[CMHUserData alloc] initWithInternalUser:newUser];
        block(error);
    }];
}

- (void)uploadUserConsent:(ORKTaskResult *)consentResult withCompletion:(CMHUploadConsentCompletion)block
{
    [self uploadUserConsent:consentResult forStudyWithDescriptor:nil andCompletion:block];
}

- (void)uploadUserConsent:(ORKTaskResult *)consentResult forStudyWithDescriptor:(NSString *)descriptor andCompletion:(CMHUploadConsentCompletion)block
{
    NSError *consentError = nil;
    ORKConsentSignature *signature = [CMHConsentValidator signatureFromConsentResults:consentResult error:&consentError];

    if (nil != consentError) {
        if (nil != block) {
            block(nil, consentError);
        }
        return;
    }

    if (![[CMHInternalUser currentUser] isLoggedIn]) {
        if (nil != block) {
            NSError *loggedOutError = [CMHErrorUtilities errorWithCode:CMHErrorUserNotLoggedIn localizedDescription:@"Must be logged in to upload consent"];
            block(nil, loggedOutError);
        }

        return;
    }

    [self conditionallySaveNameFromSignature:signature withCompletion:^(NSError * _Nullable error) {
        if (nil != error) {
            if (nil != block) {
                block(nil, error);
            }
            return;
        }

        NSData *signatureData = UIImageJPEGRepresentation(signature.signatureImage, 1.0);

        [[CMStore defaultStore] saveUserFileWithData:signatureData additionalOptions:nil callback:^(CMFileUploadResponse *fileResponse) {
            NSError *fileUploadError = [CMHErrorUtilities errorForFileKind:NSLocalizedString(@"signature", nil) uploadResponse:fileResponse];
            if (nil != fileUploadError) {
                if (nil != block) {
                    block(nil, fileUploadError);
                }
                return;
            }

            CMHConsent *consent = [[CMHConsent alloc] initWithConsentResult:consentResult
                                                  andSignatureImageFilename:fileResponse.key
                                                     forStudyWithDescriptor:descriptor];
            
            [consent saveWithUser:[CMHInternalUser currentUser] callback:^(CMObjectUploadResponse *response) {
                if (nil == block) {
                    return;
                }

                NSError *consentUploadError = [CMHErrorUtilities errorForConsentWithObjectId:consent.objectId uploadResponse:response];
                if (nil != consentUploadError) {
                    block(nil, consentUploadError);
                    return;
                }

                block(consent, nil);
            }];
        }];
    }];
}

- (void)fetchUserConsentForStudyWithCompletion:(CMHFetchConsentCompletion)block
{
    [self fetchUserConsentForStudyWithDescriptor:nil andCompletion:block];
}

- (void)fetchUserConsentForStudyWithDescriptor:(NSString *_Nullable)descriptor
                                 andCompletion:(_Nullable CMHFetchConsentCompletion)block
{
    if (nil == descriptor) {
        descriptor = @"";
    }

    NSString *queryString = [NSString stringWithFormat:@"[%@ = \"%@\", %@ = \"%@\"]", CMInternalClassStorageKey, [CMHConsent class], CMHStudyDescriptorKey, descriptor];

    [[CMStore defaultStore] searchUserObjects:queryString
                            additionalOptions:nil
                                     callback:^(CMObjectFetchResponse *response)
    {
        if (nil == block) {
            return;
        }

        NSError *error = [CMHUser errorForConsentWithFetchResponse:response];

        if (nil != error) {
            block(nil, error);
            return;
        }

        if (response.count == 0) {
            block(nil, nil);
            return;
        }

        CMHConsent *firstConsent = response.objects.firstObject;
        block(firstConsent, nil);
    }];
}

- (void)loginWithEmail:(NSString *_Nonnull)email
              password:(NSString *_Nonnull)password
         andCompletion:(_Nullable CMHUserAuthCompletion)block
{
    NSAssert(nil != email, @"CMHUser: Attempted to login with nil email");
    NSAssert(nil != password, @"CMHUser: Attempted to login with nil password");

    self.userData = nil;
    CMHInternalUser *user = [[CMHInternalUser alloc] initWithEmail:email andPassword:password];
    [CMStore defaultStore].user = user;

    [user loginWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
        NSError *error = [CMHErrorUtilities errorForAccountResult:resultCode];
        if (nil != error) {
            if (nil != block) {
                block(error);
            }
            return;
        }

        self.userData = [[CMHUserData alloc] initWithInternalUser:[CMHInternalUser currentUser]];

        if (nil != block) {
            block(nil);
        }
    }];
}

- (void)resetPasswordForAccountWithEmail:(NSString *_Nonnull)email
                          withCompletion:(_Nullable CMHResetPasswordCompletion)block
{
     NSAssert(nil != email, @"CMHUser: Attempted to reset password for account with nil email");

    CMUser *resetUser = [[CMUser alloc] initWithEmail:email andPassword:@""];
    [resetUser resetForgottenPasswordWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
        if (nil == block) {
            return;
        }

        NSError *resetError = [CMHErrorUtilities errorForAccountResult:resultCode];
        block(resetError);
    }];
}

- (void)logoutWithCompletion:(_Nullable CMHUserLogoutCompletion)block
{
    [[CMHInternalUser currentUser] logoutWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
        NSError *error = [CMHErrorUtilities errorForAccountResult:resultCode];
        if (nil != error) {
            if (nil != block) {
                block(error);
            }
            return;
        }

        self.userData = nil;

        if (nil != block) {
            block(nil);
        }
    }];
}

- (BOOL)isLoggedIn
{
    return nil != [CMHInternalUser currentUser] && [CMHInternalUser currentUser].isLoggedIn;
}

# pragma mark Private

- (void)conditionallySaveNameFromSignature:(ORKConsentSignature *_Nonnull)signature withCompletion:(void (^)(NSError *error))block
{
    CMHInternalUser *user = [CMHInternalUser currentUser];
    if (user.hasName) {
        block(nil);
        return;
    }

    user.familyName = signature.familyName;
    user.givenName = signature.givenName;

    [user save:^(CMUserAccountResult resultCode, NSArray *messages) {
        NSError *error = [CMHErrorUtilities errorForAccountResult:resultCode];
        if (nil != error) {
            if (nil != block) {
                block(error);
            }
            return;
        }

        self.userData = [[CMHUserData alloc] initWithInternalUser:user];
        block(nil);
    }];
}

#pragma mark Error Generators

+ (NSError *_Nullable)errorForConsentWithFetchResponse:(CMObjectFetchResponse *_Nullable)response
{
    NSError *responseError = response.error;

    if (nil == responseError) {
        responseError = response.objectErrors[response.objectErrors.allKeys.firstObject];
    }

    if (nil != responseError) {
        NSString *message = [NSString localizedStringWithFormat:@"Failed to fetch consent; %@", responseError.localizedDescription];
        return [CMHErrorUtilities errorWithCode:CMHErrorFailedToFetchConsent localizedDescription:message];
    }

    return nil;
}

@end
