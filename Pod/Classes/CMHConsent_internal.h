#ifndef CMHConsent_internal_h
#define CMHConsent_internal_h

#import "CMHConsent.h"

@interface CMHConsent ()
- (_Nonnull instancetype)initWithConsentResult:(ORKTaskResult *_Nullable)consentResult
                     andSignatureImageFilename:(NSString *_Nullable)filename
                        forStudyWithDescriptor:(NSString *_Nullable)descriptor;

@property (nonatomic, nullable, readwrite) ORKTaskResult *consentResult;
@property (nonatomic, nullable, readwrite) NSString *studyDescriptor;

@property (nonatomic, nullable) NSString *signatureImageFilename;
@property (nonatomic, nullable) NSString *pdfFileName;
@property (nonatomic, nullable) UIImage *signatureImage;
@property (nonatomic, nullable) NSData *pdfData;

@end

#endif
