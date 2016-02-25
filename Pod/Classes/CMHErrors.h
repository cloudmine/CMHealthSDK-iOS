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
    CMHErrorUserNotLoggedIn         = 706,
    CMHErrorResetInvalidAcct        = 707,
    CMHErrorResetUnknownResult      = 708
};

#endif
