#import "CMHAutoPager.h"
#import <CloudMine/CloudMine.h>
#import "CMHDisptachUtils.h"
#import "CMHInternalProfile.h"
#import "CMHErrorUtilities.h"
#import "CMHConstants_internal.h"

static const NSInteger kCMHAutoPagerLimit = 25;
static NSString * const _Nonnull CMInternalUpdatedKey = @"__updated__";

@implementation CMHAutoPager

+ (void)fetchAllUsersWithCompletion:(nonnull CMHAllUsersCompletion)block
{
    NSAssert(nil != block, @"Cannot call %s without completion block", __PRETTY_FUNCTION__);
    
    dispatch_queue_t highQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(highQueue, ^{
        
        NSMutableArray *mutableAllUsers = [NSMutableArray new];
        NSMutableArray *mutableAllErrors = [NSMutableArray new];
        __block NSUInteger lastFetchCount = 0;
        __block NSUInteger lastErrorCount = 0;
        NSInteger skipCount = 0;
        
        do {
            NSLog(@"[CMHealth] Fetching Users with page count: %li", (long)skipCount);
            
            cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                CMStoreOptions *limit = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:kCMHAutoPagerLimit skip:(skipCount * kCMHAutoPagerLimit)]];
                [CMUser allUserWithOptions:limit callback:^(CMObjectFetchResponse *response) {
                    if (nil != response.objects) {
                        lastFetchCount = response.objects.count;
                        [mutableAllUsers addObjectsFromArray:response.objects];
                    }
                    
                    if (response.objectErrors.allValues.count > 0) {
                        [mutableAllErrors addObjectsFromArray:response.objectErrors.allValues];
                        lastErrorCount = response.objectErrors.allValues.count;
                    }
                    
                    if (nil != response.error) {
                        [mutableAllErrors addObject:response.error];
                        lastErrorCount += 1;
                    }
                    
                    done();
                }];
            });
            
            skipCount += 1;
            
        } while (lastFetchCount >= kCMHAutoPagerLimit && lastErrorCount == 0);
        
        block([mutableAllUsers copy], [mutableAllErrors copy]);
    });
}

+ (void)fetchAllUserProfilesWithCompletion:(nonnull CMHAllProfilesCompletion)block
{
    NSAssert(nil != block, @"Cannot call %s without completion block", __PRETTY_FUNCTION__);
    
    dispatch_queue_t highQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(highQueue, ^{
        NSMutableArray *mutableAllProfiles =  [NSMutableArray new];
        __block NSError *fetchError = nil;
        __block NSUInteger lastFetchCount = 0;
        NSInteger skipCount = 0;
        
        do {
            NSLog(@"[CMHealth] Fetching user profiles with page count: %li", (long)skipCount);
            
            cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                CMStoreOptions *limitSharedOption = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:kCMHAutoPagerLimit skip:(skipCount * kCMHAutoPagerLimit)]];
                limitSharedOption.shared = YES;
                
                NSString *query = [NSString stringWithFormat:@"[%@ = \"%@\"]", CMInternalClassStorageKey, [CMHInternalProfile class]];
                [[CMStore defaultStore] searchUserObjects:query additionalOptions:limitSharedOption callback:^(CMObjectFetchResponse *response) {
                    NSError *error = [CMHErrorUtilities errorForFetchWithResponse:response];
                    if (nil != error) {
                        fetchError = error;
                    }
                    
                    if (nil != response.objects) {
                        [mutableAllProfiles addObjectsFromArray:response.objects];
                        lastFetchCount = response.objects.count;
                    }
                    
                    done();
                }];
            });
            
            skipCount += 1;
            
        } while (lastFetchCount >= kCMHAutoPagerLimit && nil == fetchError);
        
        block([mutableAllProfiles copy], fetchError);
    });
}

+ (void)fetchObjectsWithOwningUser:(NSString *)owningUserIdentifier updatedAfter:(NSString *)updateAfterStamp withCompletion:(CMHFetchObjectsCompletion)block
{
    NSAssert(nil != owningUserIdentifier, @"Cannot call %s without providing owning user identifier", __PRETTY_FUNCTION__);
    NSAssert(nil != updateAfterStamp, @"Cannot call %s without providing update-after stamp", __PRETTY_FUNCTION__);
    NSAssert(nil != block, @"Cannot call %s without completion block", __PRETTY_FUNCTION__);
    
    dispatch_queue_t highQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(highQueue, ^{
        NSMutableArray *mutableAllObjects = [NSMutableArray new];
        __block NSError *fetchError = nil;
        __block NSUInteger lastFetchCount = 0;
        NSInteger skipCount = 0;
        
        do {
            NSLog(@"[CMHealth] Fetching user objects with page count: %li", (long)skipCount);
            
            cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                CMStoreOptions *limitSharedOption = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:kCMHAutoPagerLimit skip:(skipCount * kCMHAutoPagerLimit)]];
                limitSharedOption.shared = YES;
                
                NSString *query = [NSString stringWithFormat:@"[%@ = \"%@\", %@ >= \"%@\"]", CMHOwningUserKey, owningUserIdentifier, CMInternalUpdatedKey, updateAfterStamp];
                
                [[CMStore defaultStore] searchUserObjects:query additionalOptions:limitSharedOption callback:^(CMObjectFetchResponse *response) {
                    NSError *error = [CMHErrorUtilities errorForFetchWithResponse:response];
                    if (nil != error) {
                        fetchError = error;
                    }
                    
                    if (nil != response.objects) {
                        [mutableAllObjects addObjectsFromArray:response.objects];
                        lastFetchCount = response.objects.count;
                    }
                    
                    done();
                }];
            });
            
            skipCount += 1;
            
        } while (lastFetchCount >= kCMHAutoPagerLimit && nil == fetchError);
        
        block([mutableAllObjects copy], fetchError);
    });
}

@end
