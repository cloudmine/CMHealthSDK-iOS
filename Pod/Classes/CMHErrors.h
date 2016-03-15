#import <Foundation/Foundation.h>

#ifndef CMHErrors_h
#define CMHErrors_h

static NSString *const CMHErrorDomain = @"me.cloudmine.CMHealth.ErrorDomain";

/** These constants represent the possible error codes that will be returned by 
 *  CMHealth networking calls within the `CMHErrorDomain`.
 */
typedef NS_ENUM(NSUInteger, CMHError) {
    CMHErrorUserMissingConsent      = 700,
    CMHErrorUserMissingSignature    = 701,
    CMHErrorUserDidNotConsent       = 702,
    CMHErrorUserDidNotProvideName   = 703,
    CMHErrorUserDidNotSign          = 704,
    CMHErrorFailedToUploadFile      = 705,
    CMHErrorFailedToUploadConsent   = 706,
    CMHErrorUserNotLoggedIn         = 707,
    CMHErrorInvalidAccount          = 708,
    CMHErrorInvalidCredentials      = 709,
    CMHErrorDuplicateAccount        = 710,
    CMHErrorInvalidUserRequest      = 711,
    CMHErrorUnknownAccountError     = 712,
    CMHErrorFailedToFetchConsent    = 713,
    CMHErrorUnknown                 = 800,
    CMHErrorServerConnectionFailed  = 801,
    CMHErrorServerError             = 802,
    CMHErrorNotFound                = 803,
    CMHErrorInvalidRequest          = 804,
    CMHErrorInvalidResponse         = 805,
    CMHErrorUnauthorized            = 806,
};

#endif
