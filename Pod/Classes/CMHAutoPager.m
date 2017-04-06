#import "CMHAutoPager.h"
#import <CloudMine/CloudMine.h>
#import "CMHDisptachUtils.h"

static const NSInteger kCMHAutoPagerLimit = 25;

@implementation CMHAutoPager

+ (void)fetchAllUsersWithCompletion:(nonnull CMHAllUserCompletion)block
{
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

@end
