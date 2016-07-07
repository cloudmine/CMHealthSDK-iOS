#import "CMHOnboardingValidator.h"
#import "CMHErrorUtilities.h"
#import "CMHRegistrationData.h"

@implementation CMHOnboardingValidator

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

    if (nil == signature.signatureImage) {
        *errorPtr = [CMHErrorUtilities errorWithCode:CMHErrorUserDidNotSign
                                localizedDescription:NSLocalizedString(@"Must provide signature image", nil)];
        return nil;
    }

    return signature;
}

+ (CMHRegistrationData *_Nullable)dataFromRegistrationResults:(ORKTaskResult *_Nullable)registrationResult error:(NSError * __autoreleasing _Nullable * _Nullable)errorPtr
{
    if (nil == registrationResult) {
        *errorPtr = [CMHErrorUtilities errorWithCode:CMHErrorUserMissingRegistration
                                localizedDescription:NSLocalizedString(@"Must include a registration step", nil)];
        return nil;
    }

    CMHRegistrationData *regData = [CMHOnboardingValidator registrationDataInResults:registrationResult.results];

    if (nil == regData) {
        *errorPtr = [CMHErrorUtilities errorWithCode:CMHErrorUserMissingRegistration
                                localizedDescription:NSLocalizedString(@"Must include a registration step", nil)];
        return nil;
    }

    return regData;
}

# pragma mark Private
+ (CMHRegistrationData *_Nullable)registrationDataInResults:(NSArray<ORKResult *> *_Nullable)results
{
    if (nil == results) {
        return nil;
    }

    for (ORKResult *aResult in results) {
        if (NO == [aResult isKindOfClass:[ORKCollectionResult class]]) {
            continue;
        }

        CMHRegistrationData *registrationData = [CMHRegistrationData registrationDataFromResult:aResult];
        if (nil != registrationData) {
            return registrationData;
        }
    }

    for (ORKResult *aResult in results) {
        if (NO == [aResult isKindOfClass:[ORKCollectionResult class]]) {
            continue;
        }

        CMHRegistrationData *recusriveData = [self registrationDataInResults:[aResult performSelector:@selector(results)]];
        if (nil != recusriveData) {
            return recusriveData;
        }
    }

    return nil;
}

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

@end
