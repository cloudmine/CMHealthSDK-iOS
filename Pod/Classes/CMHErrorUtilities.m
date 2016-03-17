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

+ (NSError *_Nullable)errorForKind:(NSString *_Nullable)kind objectId:(NSString *_Nonnull)objectId uploadResponse:(CMObjectUploadResponse *_Nullable)response
{
    if (nil == kind) {
        kind = @"object";
    }

    if (nil != response.error) {
        NSString *responseErrorMessage = [NSString localizedStringWithFormat:@"Failed to upload %@; %@", kind, response.error.localizedDescription];
        return [CMHErrorUtilities errorWithCode:CMHErrorFailedToUploadObject localizedDescription:responseErrorMessage];
    }

    if (nil == response.uploadStatuses || nil == [response.uploadStatuses objectForKey:objectId]) {
        return [CMHErrorUtilities errorWithCode:CMHErrorFailedToUploadObject
                           localizedDescription:[NSString localizedStringWithFormat:@"Failed to upload %@; no response received", kind]];
    }

    NSString *resultUploadStatus = [response.uploadStatuses objectForKey:objectId];

    if(![@"created" isEqualToString:resultUploadStatus] && ![@"updated" isEqualToString:resultUploadStatus]) {
        NSString *invalidStatusMessage = [NSString localizedStringWithFormat:@"Failed to upload %@kind; invalid upload status returned: %@", kind, resultUploadStatus];
        return [CMHErrorUtilities errorWithCode:CMHErrorFailedToUploadObject localizedDescription:invalidStatusMessage];
    }

    return nil;
}

+ (NSError *_Nullable)errorForKind:(NSString *_Nullable)kind fetchResponse:(CMObjectFetchResponse *_Nullable)response
{
    if (nil == kind) {
        kind = @"file";
    }

    NSError *responseError = response.error;

    if (nil == responseError) {
        responseError = response.objectErrors[response.objectErrors.allKeys.firstObject];
    }

    if (nil != responseError) {
        NSString *message = [NSString localizedStringWithFormat:@"Failed to fetch %@; %@", kind,  responseError.localizedDescription];
        return [self errorWithCode:CMHErrorFailedToFetchObject localizedDescription:message];
    }

    return nil;
}

+ (NSError *_Nullable)errorForAccountResult:(CMUserAccountResult)resultCode
{
    if (CMUserAccountOperationSuccessful(resultCode)) {
        return nil;
    }

    NSString *errorMessage = nil;
    CMHError code = -1;

    switch (resultCode) {
        case CMUserAccountCreateFailedInvalidRequest:
            code = CMHErrorInvalidUserRequest;
            errorMessage = NSLocalizedString(@"Request was invalid", nil);
            break;
        case CMUserAccountProfileUpdateFailed:
            code = CMHErrorUnknownAccountError;
            errorMessage = NSLocalizedString(@"Failed to update profile", nil);
            break;
        case CMUserAccountCreateFailedDuplicateAccount:
            code = CMHErrorDuplicateAccount;
            errorMessage = NSLocalizedString(@"Duplicate account email", nil);
            break;
        case CMUserAccountCredentialChangeFailedDuplicateEmail:
        case CMUserAccountCredentialChangeFailedDuplicateUsername:
        case CMUserAccountCredentialChangeFailedDuplicateInfo:
            code = CMHErrorDuplicateAccount;
            errorMessage = NSLocalizedString(@"Duplicate account data", nil);
            break;
        case CMUserAccountLoginFailedIncorrectCredentials:
        case CMUserAccountCredentialChangeFailedInvalidCredentials:
        case CMUserAccountPasswordChangeFailedInvalidCredentials:
            code = CMHErrorInvalidCredentials;
            errorMessage = NSLocalizedString(@"Invalid username or password", nil);
            break;
        case CMUserAccountOperationFailedUnknownAccount:
            code = CMHErrorInvalidAccount;
            errorMessage = NSLocalizedString(@"Account does not exist", nil);
            break;
        default:
            code = CMHErrorUnknownAccountError;
            errorMessage = [NSString localizedStringWithFormat:@"Unknown account error with code: %li", (long)resultCode];
            break;
    }

    return [self errorWithCode:code localizedDescription:errorMessage];
}

+ (CMHError)localCodeForCloudMineCode:(CMErrorCode)code
{
    switch (code) {
        case CMErrorUnknown:
            return CMHErrorUnknown;
        case CMErrorServerConnectionFailed:
            return CMHErrorServerConnectionFailed;
        case CMErrorServerError:
            return CMHErrorServerError;
        case CMErrorNotFound:
            return CMHErrorNotFound;
        case CMErrorInvalidRequest:
            return CMHErrorInvalidRequest;
        case CMErrorInvalidResponse:
            return CMHErrorInvalidResponse;
        case CMErrorUnauthorized:
            return CMHErrorUnauthorized;
        default:
            return CMHErrorUnknown;
    }
}

+ (NSString *_Nonnull)messageForCode:(CMHError)errorCode
{
    switch (errorCode) {
        case CMHErrorServerConnectionFailed:
            return NSLocalizedString(@"Connection to the server failed", nil);
        case CMHErrorServerError:
            return NSLocalizedString(@"A server error occurred", nil);
        case CMHErrorNotFound:
            return NSLocalizedString(@"Requested object was not found", nil);
        case CMHErrorInvalidRequest:
            return NSLocalizedString(@"The request was invalid", nil);
        case CMHErrorInvalidResponse:
            return NSLocalizedString(@"The response was invalid", nil);
        case CMHErrorUnauthorized:
            return NSLocalizedString(@"The request was unauthorized", nil);
        case CMHErrorUnknown:
        default:
            return NSLocalizedString(@"An unknown error occurred", nil);
            break;
    }
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
