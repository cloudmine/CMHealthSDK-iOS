#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>

@interface CMHConsentValidator : NSObject

+ (ORKConsentSignature *_Nullable)signatureFromConsentResults:(ORKTaskResult *_Nullable)consentResult error:(NSError * __autoreleasing _Nullable * _Nullable)errorPtr;

@end
