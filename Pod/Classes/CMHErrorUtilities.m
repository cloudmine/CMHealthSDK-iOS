#import "CMHErrorUtilities.h"

@implementation CMHErrorUtilities

+ (NSError *_Nonnull)errorWithCode:(CMHError)code localizedDescription:(NSString *_Nonnull)description
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: description };
    NSError *error = [NSError errorWithDomain:CMHErrorDomain code:code userInfo:userInfo];
    return error;
}

+ (NSError *_Nullable)errorForFileKind:(NSString *_Nullable)fileKind uploadResponse:(CMFileUploadResponse *_Nullable)response
{
    if (nil != response.error) {
        NSString *fileUploadMessage = [NSString localizedStringWithFormat:@"Failed to upload %@; %@", fileKind, response.error.localizedDescription];
        NSError *fileUploadError = [self errorWithCode:CMHErrorFailedToUploadFile
                                               localizedDescription:fileUploadMessage];
        return fileUploadError;
    }

    return [self errorForFileUploadResult:response.result];
}

+ (NSError *_Nullable)errorForConsentWithObjectId:(NSString *_Nonnull)objectId uploadResponse:(CMObjectUploadResponse *_Nullable)response
{
    if (nil != response.error) {
        NSString *responseErrorMessage = [NSString localizedStringWithFormat:@"Failed to upload user consent; %@", response.error.localizedDescription];
        return [CMHErrorUtilities errorWithCode:CMHErrorFailedToUploadConsent localizedDescription:responseErrorMessage];
    }

    if (nil == response.uploadStatuses || nil == [response.uploadStatuses objectForKey:objectId]) {
        return [CMHErrorUtilities errorWithCode:CMHErrorFailedToUploadConsent
                           localizedDescription:NSLocalizedString(@"Failed to upload user consent; no response received", nil)];
    }

    NSString *resultUploadStatus = [response.uploadStatuses objectForKey:objectId];

    if(![@"created" isEqualToString:resultUploadStatus] && ![@"updated" isEqualToString:resultUploadStatus]) {
        NSString *invalidStatusMessage = [NSString localizedStringWithFormat:@"Failed to upload user consent; invalid upload status returned: %@", resultUploadStatus];
        return [CMHErrorUtilities errorWithCode:CMHErrorFailedToUploadConsent localizedDescription:invalidStatusMessage];
    }

    return nil;
}

#pragma mark Private

+ (NSError * _Nullable)errorForFileUploadResult:(CMFileUploadResult)result
{
    switch (result) {
        case CMFileCreated:
            return nil;
        case CMFileUpdated:
            return [self errorWithCode:CMHErrorFailedToUploadFile
                               localizedDescription:NSLocalizedString(@"Overwrote an existing file while saving", nil)];
        case CMFileUploadFailed:
        default:
            return [self errorWithCode:CMHErrorFailedToUploadFile
                               localizedDescription:NSLocalizedString(@"Failed to upload file", nil)];
    }
}

@end
