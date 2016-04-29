#import "ORKResult+CMHealth.h"
#import <CloudMine/CloudMine.h>
#import "CMHResult.h"
#import "Cocoa+CMHealth.h"
#import "ResearchKit+CMHealth.h"
#import "CMHConstants_internal.h"
#import "CMHErrors.h"
#import "CMHErrorUtilities.h"

@implementation ORKResult (CMHealth)
@end

@implementation ORKTaskResult (CMHealth)

#pragma mark Public API

- (void)cmh_saveWithCompletion:(_Nullable CMHSaveCompletion)block
{
    [self cmh_saveToStudyWithDescriptor:nil withCompletion:block];
}

- (void)cmh_saveToStudyWithDescriptor:(NSString *_Nullable)descriptor withCompletion:(_Nullable CMHSaveCompletion)block;
{
    CMHResult *resultWrapper = [[CMHResult alloc] initWithResearchKitResult:self andStudyDescriptor:descriptor];

    [resultWrapper saveWithUser:[CMStore defaultStore].user callback:^(CMObjectUploadResponse *response) {
        if (nil == block) {
            return;
        }

        NSError *error = [ORKTaskResult errorForUploadWithObjectId:resultWrapper.objectId uploadResponse:response];
        if (nil != error) {
            block(nil, error);
            return;
        }

        block(response.uploadStatuses[resultWrapper.objectId], nil);
    }];
}

+ (void)cmh_fetchUserResultsWithCompletion:(_Nullable CMHFetchCompletion)block
{
    [self cmh_fetchUserResultsForStudyWithDescriptor:nil withCompletion:block];
}

+ (void)cmh_fetchUserResultsForStudyWithDescriptor:(NSString *_Nullable)descriptor withCompletion:(_Nullable CMHFetchCompletion)block;
{
    [self cmh_fetchUserResultsForStudyWithDescriptor:descriptor andQuery:nil withCompletion:block];
}

+ (void)cmh_fetchUserResultsForStudyWithIdentifier:(NSString *_Nullable)identifier withCompletion:(_Nullable CMHFetchCompletion)block
{
    [self cmh_fetchUserResultsForStudyWithDescriptor:nil andIdentifier:identifier withCompletion:block];
}

+ (void)cmh_fetchUserResultsForStudyWithDescriptor:(NSString *_Nullable)descriptor andIdentifier:(NSString *_Nullable)identifier withCompletion:(_Nullable CMHFetchCompletion)block
{
    NSString *query = nil;
    if (nil != identifier) {
        query = [NSString stringWithFormat:@"[identifier = \"%@\"]", identifier];
    }

    [self cmh_fetchUserResultsForStudyWithDescriptor:descriptor andQuery:query withCompletion:block];
}

+ (void)cmh_fetchUserResultsForStudyWithQuery:(NSString *_Nullable)query
                               withCompletion:(_Nullable CMHFetchCompletion)block
{
    [self cmh_fetchUserResultsForStudyWithDescriptor:nil andQuery:query withCompletion:block];
}

+ (void)cmh_fetchUserResultsForStudyWithDescriptor:(NSString *_Nullable)descriptor
                                          andQuery:(NSString *_Nullable)query
                                    withCompletion:(_Nullable CMHFetchCompletion)block
{
    if (nil == descriptor) {
        descriptor = @"";
    }

    NSString *composedQuery = [NSString stringWithFormat:@"[%@ = \"%@\", %@ = \"%@\"]", CMInternalClassStorageKey, [CMHResult class], CMHStudyDescriptorKey, descriptor];

    if (nil != query) {
        composedQuery = [NSString stringWithFormat:@"%@.rkResult%@", composedQuery, query];
    }

    [[CMStore defaultStore] searchUserObjects:composedQuery
                            additionalOptions:nil
                                     callback:^(CMObjectFetchResponse *response)
     {
         if (nil == block) {
             return;
         }

         NSError *error = [ORKTaskResult errorForFetchWithResponse:response];
         if (nil != error) {
             block(nil, error);
             return;
         }

         NSMutableArray *mutableResults = [NSMutableArray new];
         for (CMHResult *wrappedResult in response.objects) {
             if (nil == wrappedResult.rkResult || ![wrappedResult.rkResult isKindOfClass:[self class]]) {
                 continue;
             }

             [mutableResults addObject:wrappedResult.rkResult];
         }

         block([mutableResults copy], nil);
     }];
}

# pragma mark Error Generators
+ (NSError *_Nullable)errorForFetchWithResponse:(CMObjectFetchResponse *_Nullable)response
{
    NSString *errorPrefix = NSLocalizedString(@"Failed to fetch results", nil);

    NSError *responseError = [self errorForInternalError:response.error withPrefix:errorPrefix];
    if (nil != responseError) {
        return responseError;
    }

    // Note: an error with any result will cause an error for the whole fetch.
    // This decision keeps the API simple, but is there a compelling reason why
    // we wouldn't want this?
    NSString *objectInternalErrorMessage = response.objectErrors[response.objectErrors.allKeys.firstObject][@"message"];
    NSString *errorKey = response.objectErrors.allKeys.firstObject;

    if(nil != objectInternalErrorMessage) {
        NSString *objectErrorMessage = [NSString localizedStringWithFormat:@"%@; there was an error with at least one object: %@ (key: %@)", errorPrefix, objectInternalErrorMessage, errorKey];
        return [CMHErrorUtilities errorWithCode:CMHErrorUnknown localizedDescription:objectErrorMessage];
    }

    return nil;
}

+ (NSError *_Nullable)errorForUploadWithObjectId:(NSString *_Nonnull)objectId uploadResponse:(CMObjectUploadResponse *)response
{
    NSString *errorPrefix = NSLocalizedString(@"Failed to save results", nil);

    NSError *responseError = [self errorForInternalError:response.error withPrefix:errorPrefix];
    if (nil != responseError) {
        return responseError;
    }

    if (nil == response.uploadStatuses || nil == [response.uploadStatuses objectForKey:objectId]) {
        NSString *noStatusMessage = [NSString localizedStringWithFormat:@"%@. No response received", errorPrefix];
        return [CMHErrorUtilities errorWithCode:CMHErrorInvalidResponse
                           localizedDescription:noStatusMessage];
    }

    NSString *resultUploadStatus = [response.uploadStatuses objectForKey:objectId];

    if(![@"created" isEqualToString:resultUploadStatus] && ![@"updated" isEqualToString:resultUploadStatus]) {
        NSString *invalidStatusMessage = [NSString localizedStringWithFormat:@"%@. Invalid upload status returned: %@", errorPrefix, resultUploadStatus];
        return [CMHErrorUtilities errorWithCode:CMHErrorInvalidResponse localizedDescription:invalidStatusMessage];
    }

    return nil;
}

+ (NSError *_Nullable)errorForInternalError:(NSError *_Nullable)error withPrefix:(NSString *_Nonnull)prefix
{
    if (nil == error) {
        return nil;
    }

    if (![error.domain isEqualToString:CMErrorDomain]) {
        NSString *unknownMessage = [NSString stringWithFormat:@"%@. %@ (%@, %li)", prefix, error.localizedDescription, error.domain, error.code];
        return [CMHErrorUtilities errorWithCode:CMHErrorUnknown localizedDescription:unknownMessage];
    }

    CMHError localCode = [CMHErrorUtilities localCodeForCloudMineCode:error.code];
    NSString *message = [NSString stringWithFormat:@"%@. %@", prefix, [CMHErrorUtilities messageForCode:localCode]];

    return [CMHErrorUtilities errorWithCode:localCode localizedDescription:message];
}

@end
