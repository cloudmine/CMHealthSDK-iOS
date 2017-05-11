#import "CMHCareDeleteOperation.h"
#import "CMHCareActivity.h"
#import "CMHDisptachUtils.h"

@interface CMHCareDeleteOperation ()

@property (nonatomic, nonnull) CMHCareActivity *careActvity;

@end

@implementation CMHCareDeleteOperation

#pragma mark Initialization

- (instancetype)init
{
    NSAssert(false, @"%s is unavailable on %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}

- (instancetype)initWithActivity:(CMHCareActivity *)activity
{
    NSAssert(nil != activity, @"Cannot instantiate %@ without an activity to delete", [self class]);
    NSAssert(!activity.isDeleted, @"Attempted to queue an activity marked as deleted. *Removing* an activity server side should only be done on the version *not* marked as deleted");
    
    self = [super init];
    if (nil == self || nil == activity) { return nil; }
    
    _careActvity = activity;
    self.queuePriority = NSOperationQueuePriorityHigh;
    
    return self;
}

#pragma mark NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil == self) { return nil; }
    
    _careActvity = [aDecoder decodeObjectForKey:@"careActivity"];
    self.queuePriority = NSOperationQueuePriorityHigh;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.careActvity forKey:@"careActivity"];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

#pragma mark Overrides

- (void)main
{
    NSUInteger retryCount = 0;
    
    while(true) { // retry loop
        if (self.isCancelled) {
            NSLog(@"[CMHealth] Activity deletion push cancelled");
            return;
        }
        
        __block NSString *deleteStatus = nil;
        __block NSError *deleteError = nil;
        
        cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
            [[CMStore defaultStore] deleteUserObject:self.careActvity additionalOptions:nil callback:^(CMDeleteResponse *response) {
                deleteStatus = response.success[self.careActvity.objectId];
                
                if (nil != response.error) {
                    deleteError = response.error;
                }
                
                if (nil != response.objectErrors[self.careActvity.objectId]) {
                    deleteError = response.objectErrors[self.careActvity.objectId];
                }
                
                done();
            }];
        });
        
        if (nil == deleteStatus) {
            NSTimeInterval sleepTime = [CMHCareDeleteOperation sleepTimeForRetryCount:retryCount];
            retryCount += 1;
            
            NSLog(@"[CMHealth] Error deleting Care Activity via queue %@, retrying after %f. -> %@", deleteError.localizedDescription, sleepTime, self.careActvity);
            if (self.isCancelled) {
                NSLog(@"[CMHealth] Activity deletion push canceled");
                return;
            }
            
            [NSThread sleepForTimeInterval:sleepTime];
        } else {
            NSLog(@"[CMHealth] Care Activity Object deleted via queue with status: %@ -> %@", deleteStatus, self.careActvity);
            break;
        }
    }
}

#pragma mark Helpers

+ (NSTimeInterval)sleepTimeForRetryCount:(NSUInteger)count
{
    switch (count) {
        case 0:
            return 0.1f;
        case 1:
            return 1.0f;
        case 2:
            return 2.0f;
        case 3:
            return 5.0f;
        case 4:
            return 10.0f;
        case 5:
            return 15.0f;
        default:
            return 30.0f;
    }
}

@end
