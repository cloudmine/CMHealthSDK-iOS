#import <ResearchKit/ResearchKit.h>

@class CMHUserData;
@class CMHConsent;

typedef void(^CMHUserAuthCompletion)(NSError * _Nullable error);
typedef void(^CMHUserLogoutCompletion)(NSError * _Nullable error);
typedef void(^CMHResetPasswordCompletion)(NSError *_Nullable error);
typedef void(^CMHUploadConsentCompletion)(CMHConsent *_Nullable consent, NSError *_Nullable error);
typedef void(^CMHFetchConsentCompletion)(CMHConsent *_Nullable consent, NSError *_Nullable error);

/**
 *  `CMHUser` is a singleton class representing the current user. It represents
 *  a specific logged in user linked to an account or simply the generic logged
 *  out user.
 *
 *  @see +currentUser
 */
@interface CMHUser : NSObject

/**
 *  Returns the only `CMHUser` instance. Will never return `nil`, even
 *  if the current user is not logged in.
 */
+ (_Nonnull instancetype)currentUser;

- (void)signUpWithRegistration:(ORKTaskResult *_Nullable)registrationResult
                 andCompletion:(_Nullable CMHUserAuthCompletion)block;

/**
 *  Creates a new user account and logs the current user into that account.
 *  Fails with an error if the email has an existing account.
 *
 *  @warning The behavior of this method if the current user is logged in should
 *  be considered undefined. Log the current user out before calling this method.
 *
 *  @param email The email with which to create the account. Must not be `nil`.
 *  @param password The password to assign to this user. Must not be `nil`.
 *  @param block Executed when the account is created and the user is logged in
 *  or fails with an error.
 */
- (void)signUpWithEmail:(NSString *_Nonnull)email
               password:(NSString *_Nonnull)password
          andCompletion:(_Nullable CMHUserAuthCompletion)block;

/**
 *  Convenience method for uploading user consent with an empty study descriptor.
 *
 *  @see -uploadUserConsent:forStudyWithDescriptor:andCompletion:
 */
- (void)uploadUserConsent:(ORKTaskResult *_Nullable)consentResult
           withCompletion:(_Nullable CMHUploadConsentCompletion)block;

/**
 *  Uploads an `ORKTaskResult` generated by a user consent flow in ResearchKit.
 *  Fails with an error if the current user is not logged in. Also
 *  fails with an error if the `ORKTaskResult` does not contain an instance
 *  of `ORKConsentSignatureResult` somewhere in it's hiearchy. The associated
 *  `ORKConsentSignature` must include a `familyName` and `givenName` as well as
 *  a `signatureImage`.
 *
 *  @warning The expected use is that each participant would have one consent for each
 *  study, but this is not enforced by the SDK. Uploading multiple user consents
 *  for the same study will result in undefined behavior.
 *
 *  @warning The signature image will be removed from the consent hiearchy when uploaded
 *  and stored on the remote filesystem instead.
 *
 *  @param consentResult The `ORKTaskResult` to be serialized and uploaed.
 *  @param descriptor The descriptor for the study this consent is associated with. If nil, an
 *  empty string will be used for the descriptor.
 *  @param block Executes when the upload completes successfully or fails with an error
 */
- (void)uploadUserConsent:(ORKTaskResult *_Nullable)consentResult
   forStudyWithDescriptor:(NSString *_Nullable)descriptor
            andCompletion:(_Nullable CMHUploadConsentCompletion)block;

/**
 *  Convenience method for fetching user consent with an empty study descriptor.
 *
 *  @see -fetchUserConsentForStudyWithDescriptor:andCompletion:
 */
- (void)fetchUserConsentForStudyWithCompletion:(_Nullable CMHFetchConsentCompletion)block;

/**
 *  Fetches the consent object with descriptor for the currently logged in user.
 *  Fails with an error if the current user is not logged in. Calback returns `nil`
 *  if no consent exists for the given user and study descriptor.
 *
 *  @warning The expected use is that each participant would have one consent for each
 *  study, but this is not enforced by the SDK. Uploading multiple user consents
 *  for the same study will result in undefined behavior when fetching
 *
 *  @warning The signature image will be removed from the consent hiearchy when uploaded
 *  and stored on the remote filesystem instead.
 *
 *  @see CMHUser -fetchSignatureImageWithCompletion:
 *
 *  @param descriptor The descriptor of the study consent desired.
 *  @param block Executes when fetch completes successfully or fails with an error.
 */
- (void)fetchUserConsentForStudyWithDescriptor:(NSString *_Nullable)descriptor
                                 andCompletion:(_Nullable CMHFetchConsentCompletion)block;

/**
 *  Logs into an existing account. Fails with an error if it doesn't exist or
 *  credentials are incorrect.
 *
 *  @warning The behavior of this method if the current user is logged in should
 *  be considered undefined. Log the current user out before calling this method.
 *
 *  @param email Email of an exisiting account.
 *  @param password Password for the given account.
 *  @param block Executes when authentication succeeds or fails with an error
 */
- (void)loginWithEmail:(NSString *_Nonnull)email
              password:(NSString *_Nonnull)password
         andCompletion:(_Nullable CMHUserAuthCompletion)block;

/**
 *  Resets the password for an existing account and notifies the user via email.
 *  Fails if account does not exist.
 *
 *  @warning The behavior of this method if the current user is logged in should
 *  be considered undefined. Log the current user out before calling this method.
 *
 *  @param email Email address associated with an account.
 *  @param block Executes when request succeeds or fails with an error.
 */
- (void)resetPasswordForAccountWithEmail:(NSString *_Nonnull)email
                          withCompletion:(_Nullable CMHResetPasswordCompletion)block;

/**
 *  Logs the current user out and invalidates their session serverside.
 *  
 *  @warning The behavior of this method should be considered undefined if the
 *  current user is not logged in.
 *
 *  @param block Executes when the request completes successfully or fails with an error.
 */
- (void)logoutWithCompletion:(_Nullable CMHUserLogoutCompletion)block;

/**
 *  Read-only profile data for the currently logged in user. `nil` if the
 *  the user is not logged in.
 */
@property (nonatomic, nullable, readonly) CMHUserData *userData;

/**
 *  Authentication status of the current user.
 */
@property (nonatomic, readonly) BOOL isLoggedIn;

@end
