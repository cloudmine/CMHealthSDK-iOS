#import <Foundation/Foundation.h>

#ifndef CMHErrors_h
#define CMHErrors_h

static NSString *const CMHErrorDomain = @"me.cloudmine.CMHealth.ErrorDomain";

/** These constants represent the possible error codes that will be returned by 
 *  CMHealth networking calls within the `CMHErrorDomain`.
 */
typedef NS_ENUM(NSUInteger, CMHError) {
    CMHErrorUserMissingConsent      = 700,
    CMHErrorUserMissingRegistration = 701, 
    CMHErrorUserMissingSignature    = 702,
    CMHErrorUserDidNotConsent       = 703,
    CMHErrorUserDidNotProvideName   = 704,
    CMHErrorUserDidNotSign          = 705,
    CMHErrorFailedToUploadFile      = 706,
    CMHErrorFailedToUploadObject    = 707,
    CMHErrorUserNotLoggedIn         = 708,
    CMHErrorInvalidAccount          = 709,
    CMHErrorInvalidCredentials      = 710,
    CMHErrorDuplicateAccount        = 711,
    CMHErrorInvalidUserRequest      = 712,
    CMHErrorUnknownAccountError     = 713,
    CMHErrorFailedToFetchObject     = 714,
    CMHErrorUnknown                 = 800,
    CMHErrorServerConnectionFailed  = 801,
    CMHErrorServerError             = 802,
    CMHErrorNotFound                = 803,
    CMHErrorInvalidRequest          = 804,
    CMHErrorInvalidResponse         = 805,
    CMHErrorUnauthorized            = 806,
    CMHErrorCareObjectSaveError     = 900,
};

#endif
