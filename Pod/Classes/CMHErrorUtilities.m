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
