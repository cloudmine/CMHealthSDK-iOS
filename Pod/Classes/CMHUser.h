#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>

@class CMHUserData;
@class CMHConsent;

typedef void(^CMHUserAuthCompletion)(NSError * _Nullable error);
typedef void(^CMHUserLogoutCompletion)(NSError * _Nullable error);
typedef void(^CMHUploadConsentCompletion)(NSError *_Nullable error);
typedef void(^CMHResetPasswordCompletion)(NSError *_Nullable error);
typedef void(^CMHFetchConsentCompletion)(CMHConsent *_Nullable consent, NSError *_Nullable error);

@interface CMHUser : NSObject

+ (_Nonnull instancetype)currentUser;

- (void)signUpWithEmail:(NSString *_Nonnull)email
               password:(NSString *_Nonnull)password
          andCompletion:(_Nullable CMHUserAuthCompletion)block;

- (void)uploadUserConsent:(ORKTaskResult *_Nullable)consentResult
           withCompletion:(_Nullable CMHUploadConsentCompletion)block;

- (void)uploadUserConsent:(ORKTaskResult *_Nullable)consentResult
   forStudyWithDescriptor:(NSString *_Nullable)descriptor
            andCompletion:(_Nullable CMHUploadConsentCompletion)block;

- (void)fetchUserConsentForStudyWithCompletion:(_Nonnull CMHFetchConsentCompletion)block;

- (void)fetchUserConsentForStudyWithDescriptor:(NSString *_Nullable)descriptor
                                 andCompletion:(_Nonnull CMHFetchConsentCompletion)block;

- (void)loginWithEmail:(NSString *_Nonnull)email
              password:(NSString *_Nonnull)password
         andCompletion:(_Nullable CMHUserAuthCompletion)block;

- (void)resetPasswordForAccountWithEmail:(NSString *_Nonnull)email
                          withCompletion:(_Nullable CMHResetPasswordCompletion)block;

- (void)logoutWithCompletion:(_Nullable CMHUserLogoutCompletion)block;

@property (nonatomic, nullable, readonly) CMHUserData *userData;
@property (nonatomic, readonly) BOOL isLoggedIn;

@end
