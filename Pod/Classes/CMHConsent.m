#import "CMHConsent_internal.h"
#import "Cocoa+CMHealth.h"
#import "CMHConstants_internal.h"

@implementation CMHConsent

- (_Nonnull instancetype)initWithConsentResult:(ORKTaskResult *)consentResult
                     andSignatureImageFilename:(NSString *)filename
                        forStudyWithDescriptor:(NSString *)descriptor
{
    self = [super init];
    if (nil == self) return nil;

    self.consentResult = consentResult;
    self.signatureImageFilename = filename;
    self.studyDescriptor = descriptor;

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    // TODO: Pull the wrapper class, decode the object and ensure it is of
    // the same type as the wrapper class. Set _consentResult to the wrapper.wrappedResult
    self.consentResult = [aDecoder decodeObjectForKey:@"consentResult"];
    self.signatureImageFilename = [aDecoder decodeObjectForKey:@"signatureImageFilename"];
    self.studyDescriptor = [aDecoder decodeObjectForKey:CMHStudyDescriptorKey];

    if ([@"" isEqualToString:self.studyDescriptor]) {
        self.studyDescriptor = nil;
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.consentResult forKey:@"consentResult"];
    [aCoder encodeObject:self.signatureImageFilename forKey:@"signatureImageFilename"];

    if (nil == self.studyDescriptor) {
        [aCoder encodeObject:@"" forKey:CMHStudyDescriptorKey];
    } else {
        [aCoder encodeObject:self.studyDescriptor forKey:CMHStudyDescriptorKey];
    }
}

@end
