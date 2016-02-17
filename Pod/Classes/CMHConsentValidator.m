#import "CMHConsentValidator.h"
#import "CMHErrorUtilities.h"

@implementation CMHConsentValidator

+ (ORKConsentSignature *_Nullable)signatureFromConsentResults:(ORKTaskResult *_Nullable)consentResult error:(NSError * __autoreleasing *)errorPtr
{
    if (nil == consentResult) {
        *errorPtr = [CMHErrorUtilities errorWithCode:CMHErrorUserMissingConsent
                           localizedDescription:NSLocalizedString(@"Must complete a consent step", nil)];
        return nil;
    }

    ORKConsentSignatureResult *signatureResult = [self signatureInResults:consentResult.results];
    ORKConsentSignature *signature = signatureResult.signature;

    if (nil == signatureResult || nil == signature) {
        *errorPtr = [CMHErrorUtilities errorWithCode:CMHErrorUserMissingSignature
                           localizedDescription:NSLocalizedString(@"Consent must contain a valid signature", nil)];
        return nil;
    }

    if (!signatureResult.consented) {
        *errorPtr = [CMHErrorUtilities errorWithCode:CMHErrorUserDidNotConsent
                                localizedDescription:NSLocalizedString(@"Must agree to study consent", nil)];
        return nil;
    }

    if ([self signatureIsMissingName:signature]) {
        *errorPtr = [CMHErrorUtilities errorWithCode:CMHErrorUserDidNotProvideName
                                localizedDescription:NSLocalizedString(@"Must provide family and given names", nil)];
        return nil;
    }

    if (nil == signature.signatureImage) {
        *errorPtr = [CMHErrorUtilities errorWithCode:CMHErrorUserDidNotSign
                                localizedDescription:NSLocalizedString(@"Must provide signature image", nil)];
        return nil;
    }

    return signature;
}

# pragma mark Private
+ (ORKConsentSignatureResult *_Nullable)signatureInResults:(NSArray<ORKResult *> *_Nullable)results
{
    if (nil == results) {
        return nil;
    }

    // Check these results
    for (ORKResult *aResult in results) {
        if ([aResult isKindOfClass:[ORKConsentSignatureResult class]]) {
            return (ORKConsentSignatureResult *)aResult;
        }
    }

    // Recusrively check results of results
    for (ORKResult *aResult in results) {
        if (![aResult respondsToSelector:@selector(results)]) {
            continue;
        }

        ORKConsentSignatureResult *recusrivResult = [self signatureInResults:[aResult performSelector:@selector(results)]];
        if (nil != recusrivResult) {
            return recusrivResult;
        }
    }

    return nil;
}

+ (BOOL)signatureIsMissingName:(ORKConsentSignature *_Nonnull)signature
{
    return nil == (signature.givenName || [signature.givenName isEqualToString:@""] ||
                   nil == signature.familyName || [signature.familyName isEqualToString:@""]);
}

@end
