#import "CMHUser.h"
#import "CMHUserData.h"
#import "CMHUserData_internal.h"
#import "CMHInternalUser.h"
#import "ORKResult+CMHealth.h"
#import "CMHConsentValidator.h"
#import "CMHConsent_internal.h"

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


// TODO: Ponder: this is nice from a consumption standpoint, but could leave the user in a weird place if account creation succeeds
// but uploading consent fails. Need to think more broadly about what the SDK will actually provide in terms of consent flows.
// Somehow this probably needs to be seperated into two steps: signup, upload consent.
- (void)signUpWithEmail:(NSString *_Nonnull)email
               password:(NSString *_Nonnull)password
             andConsent:(ORKTaskResult *_Nonnull)consentResult
         withCompletion:(_Nullable CMHUserAuthCompletion)block
{
    NSError *consentError = nil;
    ORKConsentSignature *signature = [CMHConsentValidator signatureFromConsentResults:consentResult error:&consentError];

    if (nil != consentError) {
        if (nil != block) {
            block(consentError);
        }
        return;
    }

    self.userData = nil;
    CMHInternalUser *newUser = [[CMHInternalUser alloc] initWithEmail:email andPassword:password];
    [CMStore defaultStore].user = newUser;

    newUser.familyName = signature.familyName;
    newUser.givenName = signature.givenName;

    [newUser createAccountAndLoginWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
        if (CMUserAccountOperationFailed(resultCode)) {
            if (nil != block) {
                NSError *accountError = [CMHUser errorWithMessage:NSLocalizedString(@"Failed to create account and login", nil)
                                                             andCode:(100 + resultCode)];
                block(accountError);
            }
            return;
        }

        self.userData = [[CMHUserData alloc] initWithInternalUser:[CMHInternalUser currentUser]];

        NSData *signatureData = UIImageJPEGRepresentation(signature.signatureImage, 1.0);

        // TODO: Generate the image name based on study id
        [[CMStore defaultStore] saveUserFileWithData:signatureData named:@"consent.jpg" additionalOptions:nil callback:^(CMFileUploadResponse *response) {
            // TODO: error handling

            CMHConsent *consent = [[CMHConsent alloc] initWithConsentResult:consentResult andSignatureImageFilename:response.key];
            [consent saveWithUser:newUser callback:^(CMObjectUploadResponse *response) {
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
        if (CMUserAccountOperationFailed(resultCode)) {
            if (nil != block) {
                NSError *error = [CMHUser errorWithMessage:NSLocalizedString(@"Failed to log in", nil)  // TODO: different domain?
                                                             andCode:(100 + resultCode)];
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
        if (CMUserAccountOperationFailed(resultCode)) {
            if (nil != block) {
                NSError *error = [CMHUser errorWithMessage:NSLocalizedString(@"Failed to logout", nil)  // TODO: different domain?
                                                             andCode:(100 + resultCode)];
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

+ (NSError * _Nullable)errorWithMessage:(NSString * _Nonnull)message andCode:(NSInteger)code
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: message };
    NSError *error = [NSError errorWithDomain:@"CMHUserAuthenticationError" code:code userInfo:userInfo];
    return error;
}

@end
