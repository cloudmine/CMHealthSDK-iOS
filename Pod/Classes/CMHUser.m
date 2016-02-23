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

    [newUser createAccountAndLoginWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
        NSError *error = [CMHUser errorForAccountResult:resultCode];
        if (nil != error) {
            if (nil != block) {
                block(error);
            }
            return;
        }

        self.userData = [[CMHUserData alloc] initWithInternalUser:newUser];
        block(nil);
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
            block(consentError);
        }
        return;
    }

    if (![[CMHInternalUser currentUser] isLoggedIn]) {
        if (nil != block) {
            NSError *loggedOutError = [CMHErrorUtilities errorWithCode:CMHErrorUserNotLoggedIn localizedDescription:@"Must be logged in to upload consent"];
            block(loggedOutError);
        }

        return;
    }

    [self conditionallySaveNameFromSignature:signature withCompletion:^(NSError * _Nullable error) {
        if (nil != error) {
            if (nil != block) {
                block(error);
            }
            return;
        }

        NSData *signatureData = UIImageJPEGRepresentation(signature.signatureImage, 1.0);

        [[CMStore defaultStore] saveUserFileWithData:signatureData additionalOptions:nil callback:^(CMFileUploadResponse *fileResponse) {
            NSError *fileUploadError = [CMHUser errorForSignatureUploadResponse:fileResponse];
            if (nil != fileUploadError) {
                if (nil != block) {
                    block(fileUploadError);
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

                if (nil != response.error) {
                    block(response.error);
                    return;
                }

                if (nil == response.uploadStatuses || nil == [response.uploadStatuses objectForKey:consent.objectId]) {
                    NSError *nullStatusError = [CMHUser errorWithMessage:@"Failed to upload user consent" andCode:100];
                    block(nullStatusError);
                    return;
                }

                NSString *resultUploadStatus = [response.uploadStatuses objectForKey:consent.objectId];
                if(![@"created" isEqualToString:resultUploadStatus] && ![@"updated" isEqualToString:resultUploadStatus]) {
                    NSString *message = [NSString localizedStringWithFormat:@"Failed to upload user consent; invalid upload status returned: %@", resultUploadStatus];
                    NSError *invalidStatusError = [CMHUser errorWithMessage:message andCode:101];
                    block(invalidStatusError);
                    return;
                }
                
                block(nil);
            }];
        }];
    }];
}

- (void)fetchUserConsentForStudyWithCompletion:(CMHFetchConsentCompletion)block
{
    [self fetchUserConsentForStudyWithDescriptor:nil andCompletion:block];
}

- (void)fetchUserConsentForStudyWithDescriptor:(NSString *_Nullable)descriptor
                                 andCompletion:(_Nonnull CMHFetchConsentCompletion)block
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

        if (nil != response.error) {
            block(nil, response.error); // TODO: Consider, should we create a custom error?
            return;
        }

        if (response.objectErrors.count > 0) {
            NSError *firstError = response.objectErrors.allKeys.firstObject;
            block(nil, firstError);
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
        NSError *error = [CMHUser errorForAccountResult:resultCode];
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

- (void)logoutWithCompletion:(_Nullable CMHUserLogoutCompletion)block
{
    [[CMHInternalUser currentUser] logoutWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
        NSError *error = [CMHUser errorForAccountResult:resultCode];
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

- (void)conditionallySaveNameFromSignature:(ORKConsentSignature *_Nonnull)signature withCompletion:(_Nonnull CMHUploadConsentCompletion)block
{
    CMHInternalUser *user = [CMHInternalUser currentUser];
    if (user.hasName) {
        block(nil);
        return;
    }

    user.familyName = signature.familyName;
    user.givenName = signature.givenName;

    [user save:^(CMUserAccountResult resultCode, NSArray *messages) {
        NSError *error = [CMHUser errorForAccountResult:resultCode];
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

+ (NSError *_Nullable)errorForAccountResult:(CMUserAccountResult)resultCode
{
    // TODO: Update this to provide complete and unique error message/codes
    if (CMUserAccountOperationFailed(resultCode)) {
        return [CMHUser errorWithMessage:[NSString localizedStringWithFormat:@"Account action failed with code: %li", (long)resultCode]
                                 andCode:(100 + resultCode)];
    }

    return nil;
}

// TODO: This method should go away once proper error generation is done
+ (NSError * _Nullable)errorWithMessage:(NSString * _Nonnull)message andCode:(NSInteger)code
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: message };
    NSError *error = [NSError errorWithDomain:@"CMHUserAuthenticationError" code:code userInfo:userInfo];
    return error;
}

+ (NSError *_Nullable)errorForSignatureUploadResponse:(CMFileUploadResponse *)response
{
    if (nil != response.error) {
        NSString *fileUploadMessage = [NSString localizedStringWithFormat:@"Failed to upload signature; %@", response.error.localizedDescription];
        NSError *fileUploadError = [CMHErrorUtilities errorWithCode:CMHErrorFailedToUploadSignature
                                                   localizedDescription:fileUploadMessage];
        return fileUploadError;
    }

    return [self errorForSignatureUploadResult:response.result];
}

+ (NSError * _Nullable)errorForSignatureUploadResult:(CMFileUploadResult)result
{
    switch (result) {
        case CMFileCreated:
            return nil;
        case CMFileUpdated:
            return [CMHErrorUtilities errorWithCode:CMHErrorFailedToUploadSignature
                               localizedDescription:NSLocalizedString(@"Overwrote an existing signature while saving", nil)];
        case CMFileUploadFailed:
        default:
            return [CMHErrorUtilities errorWithCode:CMHErrorFailedToUploadSignature
                               localizedDescription:NSLocalizedString(@"Failed to upload signature", nil)];
    }
}

@end
