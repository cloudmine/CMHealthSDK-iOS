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

        NSError *error = [CMHErrorUtilities errorForUploadWithObjectId:resultWrapper.objectId uploadResponse:response];
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

    [self cmh_internalFetchUserResultsForTopLevelQuery:composedQuery withCompletion:block];
}

+ (void)cmh_fetchUserResultsWithRunUUID:(NSUUID *_Nonnull)uuid
                         withCompletion:(_Nullable CMHFetchCompletion)block
{
    NSAssert(nil != uuid, @"You must supply a valid task run UUID when fetching a specific unique result");

    NSString *query = [NSString stringWithFormat:@"[%@ = \"%@\", %@ = \"%@\"]", CMInternalClassStorageKey, [CMHResult class], CMInternalObjectIdKey, uuid.UUIDString];

    [self cmh_internalFetchUserResultsForTopLevelQuery:query withCompletion:block];
}

# pragma mark Private Helpers

+ (void)cmh_internalFetchUserResultsForTopLevelQuery:(NSString *_Nonnull)query
                                      withCompletion:(_Nullable CMHFetchCompletion)block
{
    NSAssert(nil != query, @"Internal query for CMHResult wrapper objects cannot be nil");

    [[CMStore defaultStore] searchUserObjects:query
                            additionalOptions:nil
                                     callback:^(CMObjectFetchResponse *response)
     {
         if (nil == block) {
             return;
         }

         NSError *error = [CMHErrorUtilities errorForFetchWithResponse:response];
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

@end
