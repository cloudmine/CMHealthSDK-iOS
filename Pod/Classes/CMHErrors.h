#import <Foundation/Foundation.h>

#ifndef CMHErrors_h
#define CMHErrors_h

static NSString *const CMHErrorDomain = @"me.cloudmine.CMHealth.ErrorDomain";

typedef NS_ENUM(NSUInteger, CMHError) {
    CMHErrorUserMissingConsent      = 700,
    CMHErrorUserMissingSignature    = 701,
    CMHErrorUserDidNotConsent       = 702,
    CMHErrorUserDidNotProvideName   = 703,
    CMHErrorUserDidNotSign          = 704,
    CMHErrorFailedToUploadSignature = 705,
    CMHErrorFailedToUploadConsent   = 706,
    CMHErrorUserNotLoggedIn         = 707,
    CMHErrorInvalidAccount          = 708,
    CMHErrorInvalidCredentials      = 709,
    CMHErrorDuplicateAccount        = 710,
    CMHErrorInvalidRequest          = 711,
    CMHErrorUnknownAccountError     = 712,
    CMHErrorFailedToFetchConsent    = 713,
    CMHErrorFailedToFetchSignature  = 714,
};

#endif
