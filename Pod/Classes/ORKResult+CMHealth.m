#import "ORKResult+CMHealth.h"
#import "CMHResult.h"
#import "Cocoa+CMHealth.h"
#import "ORKConsentSignature+CMHealth.h"
#import "CMHConstants_internal.h"

@implementation ORKResult (CMHealth)

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

        if (nil != response.error) {
            block(nil, response.error);
            return;
        }

        // Thought: as we expand the functionality of the SDK, would it make sense to return the objectId to the
        // the caller so they could later fetch the same results? This would esepcially make sense if we eventually
        // want to support serializing and uploading things other than results, such as in-progress-ORKTasks that might
        // be continued by the user later
        if (nil == response.uploadStatuses || nil == [response.uploadStatuses objectForKey:resultWrapper.objectId]) {
            NSError *nullStatusError = [ORKResult errorWithMessage:@"CloudMine upload status not returned" andCode:100];
            block(nil, nullStatusError);
            return;
        }

        NSString *resultUploadStatus = [response.uploadStatuses objectForKey:resultWrapper.objectId];
        if(![@"created" isEqualToString:resultUploadStatus] && ![@"updated" isEqualToString:resultUploadStatus]) {
            NSString *message = [NSString localizedStringWithFormat:@"CloudMine invalid upload status returned: %@", resultUploadStatus];
            NSError *invalidStatusError = [ORKResult errorWithMessage:message andCode:101];
            block(nil, invalidStatusError);
            return;
        }

        block(resultUploadStatus, nil);
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

# pragma mark Private

+ (NSError * _Nullable)errorWithMessage:(NSString * _Nonnull)message andCode:(NSInteger)code
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: message };
    NSError *error = [NSError errorWithDomain:@"CMHResultSaveError" code:code userInfo:userInfo];
    return error;
}

@end
