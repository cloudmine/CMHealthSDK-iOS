#import "ORKResult+CMHealth.h"
#import "CMHResultWrapper.h"
#import "Cocoa+CMHealth.h"
#import "ORKConsentSignature+CMHealth.h"
#import "CMHConstants_internal.h"

@implementation ORKResult (CMHealth)

- (void)cmh_saveWithCompletion:(_Nullable CMHSaveCompletion)block
{
    [self cmh_saveToStudyWithDescriptor:nil withCompletion:block];
}

- (void)cmh_saveToStudyWithDescriptor:(NSString *)descriptor withCompletion:(_Nullable CMHSaveCompletion)block;
{
    Class resultWrapperClass = [CMHResultWrapper wrapperClassForResultClass:[self class]];

    NSAssert([[resultWrapperClass class] isSubclassOfClass:[CMHResultWrapper class]],
             @"Fatal Error: Result wrapper class not a result of CMHResultWrapper");

    CMHResultWrapper *resultWrapper = [[resultWrapperClass alloc] initWithResult:self studyDescriptor:descriptor];

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
    Class wrapperClass = [CMHResultWrapper wrapperClassForResultClass:[self class]];

    if (nil == descriptor) {
        descriptor = @"";
    }

    NSString *queryString = [NSString stringWithFormat:@"[%@ = \"%@\", %@ = \"%@\"]", CMInternalClassStorageKey, [self class], CMHStudyDescriptorKey, descriptor];

    [[CMStore defaultStore] searchUserObjects:queryString
                            additionalOptions:nil
                                     callback:^(CMObjectFetchResponse *response)
     {
         NSMutableArray *mutableResults = [NSMutableArray new];
         for (id object in response.objects) {
             if ([object class] != wrapperClass || ![[object wrappedResult] isKindOfClass:[self class]]) {
                 continue;
             }

             [mutableResults addObject:[object wrappedResult]];
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
