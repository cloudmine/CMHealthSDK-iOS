#import <Foundation/Foundation.h>

#ifndef CMHErrors_h
#define CMHErrors_h

static NSString *const CMHErrorDomain = @"CMHErrorDomain";

typedef NS_ENUM(NSUInteger, CMHError) {
    CMHErrorUserMissingConsent      = 700,
    CMHErrorUserMissingSignature    = 701,
    CMHErrorUserDidNotConsent       = 702,
    CMHErrorUserDidNotProvideName   = 703,
    CMHErrorUserDidNotSign          = 704
};

#endif
