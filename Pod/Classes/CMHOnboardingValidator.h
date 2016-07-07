#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>

@class CMHRegistrationData;

@interface CMHOnboardingValidator : NSObject

+ (ORKConsentSignature *_Nullable)signatureFromConsentResults:(ORKTaskResult *_Nullable)consentResult      error:(NSError * __autoreleasing _Nullable * _Nullable)errorPtr;
+ (CMHRegistrationData *_Nullable)dataFromRegistrationResults:(ORKTaskResult *_Nullable)registrationResult error:(NSError * __autoreleasing _Nullable * _Nullable)errorPtr;

@end
