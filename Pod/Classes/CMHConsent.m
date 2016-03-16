#import "CMHConsent_internal.h"
#import <CloudMine/CloudMine.h>
#import "Cocoa+CMHealth.h"
#import "CMHConstants_internal.h"
#import "CMHErrorUtilities.h"
#import "CMHErrors.h"
#import "CMHInternalUser.h"

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

- (void)uploadConsentPDF:(NSData *_Nonnull)pdfData withCompletion:(_Nullable CMHUploadPDFCompletion)block
{
    NSAssert(nil != pdfData, @"Attempted to upload nil PDF data for user consent");

    [CMStore.defaultStore saveUserFileWithData:pdfData additionalOptions:nil callback:^(CMFileUploadResponse *uploadResponse) {
        NSError *uploadError = [CMHErrorUtilities errorForFileKind:@"consent pdf" uploadResponse:uploadResponse];

        if (nil != uploadError) {
            if (nil != block) {
                block(uploadError);
            }
            return;
        }

        self.pdfFileName = uploadResponse.key;

        [self saveWithUser:[CMHInternalUser currentUser] callback:^(CMObjectUploadResponse *saveResponse) {
            if (nil == block) {
                return;
            }

            NSError *saveError = [CMHErrorUtilities errorForConsentWithObjectId:self.objectId uploadResponse:saveResponse];
            if (nil != saveError) {
                block(saveError);
                return;
            }

            block(nil);
        }];
    }];
}

- (void)fetchConsentPDFWithCompletion:(_Nullable CMHFetchConsentPDFCompletion)block
{
    if (nil != self.pdfData) {
        if (nil != block) {
            block(self.pdfData, nil);
        }

        return;
    }

    [CMStore.defaultStore userFileWithName:self.pdfFileName additionalOptions:nil callback:^(CMFileFetchResponse *response) {
        if (nil == block) {
            return;
        }

        NSError *error = [CMHConsent errorForFileFetchResponse:response];
        if (nil != error) {
            block(nil, error);
            return;
        }

        block(response.file.fileData, nil);
    }];
}

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

        NSError *error = [CMHConsent errorForFileFetchResponse:response];
        if (nil != error) {
            block(nil, error);
            return;
        }

        UIImage *image = [UIImage imageWithData:response.file.fileData];
        if (nil == image) {
            [CMHErrorUtilities errorWithCode:CMHErrorInvalidResponse
                        localizedDescription:NSLocalizedString(@"Signature image data was empty, invalid or corrupt", nil)];
            return;
        }

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
    self.pdfFileName = [aDecoder decodeObjectForKey:@"pdfFileName"];
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
    [aCoder encodeObject:self.pdfFileName forKey:@"pdfFileName"];

    if (nil == self.studyDescriptor) {
        [aCoder encodeObject:@"" forKey:CMHStudyDescriptorKey];
    } else {
        [aCoder encodeObject:self.studyDescriptor forKey:CMHStudyDescriptorKey];
    }
}

#pragma mark Error Generation
+ (NSError *_Nullable)errorForFileFetchResponse:(CMFileFetchResponse *)response
{
    if (nil == response) {
        return [CMHErrorUtilities errorWithCode:CMHErrorInvalidResponse
                           localizedDescription:NSLocalizedString(@"No response for file request", nil)];
    }

    if (nil != response.error) {
        CMHError localCode = [CMHErrorUtilities localCodeForCloudMineCode:response.error.code];
        NSString *description = [CMHErrorUtilities messageForCode:localCode];
        return [CMHErrorUtilities errorWithCode:localCode localizedDescription:description];
    }

    return nil;
}

@end
