#import "CMHConsent_internal.h"
#import "Cocoa+CMHealth.h"
#import "CMHConstants_internal.h"

@implementation CMHConsent

#pragma mark Internal

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

#pragma mark Public

- (void)fetchSignatureImageWithCompletion:(CMHFetchSignatureCompletion)block
{
    /* Return the memoized image in memory rather than re-fetching
     * This is safe because we assume the signature image will never change
     * after initially being uploaded. To be even more efficient, we could
     * cache the image on disk. */
    if (nil != self.signatureImage) {
        if (nil != block) {
            block(self.signatureImage, nil);
        }

        return;
    }

    [CMStore.defaultStore userFileWithName:self.signatureImageFilename additionalOptions:nil callback:^(CMFileFetchResponse *response) {
        if (nil == block) {
            return;
        }

        if (nil != response.error) {
            block(nil, response.error); //TODO: Local error
        }

        if (nil == response.file.fileData) {
            block(nil, nil); //TODO: create error
        }

        UIImage *image = [UIImage imageWithData:response.file.fileData];
        self.signatureImage = image;
        block(image, nil);
    }];
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

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
