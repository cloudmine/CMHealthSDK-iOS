#import "CMHCarePullOperation.h"
#import "CMHCarePlanStore_internal.h"
#import "CMHDisptachUtils.h"

@interface CMHCarePullOperation ()

@property (nonatomic, nonnull) CMHCarePlanStore *store;
@property (nonatomic, nullable) CMHRemoteSyncCompletion block;

@end

@implementation CMHCarePullOperation

#pragma mark Initialization

- (instancetype)init
{
    NSAssert(false, @"%s is unavailable on %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}

- (instancetype)initWithStore:(CMHCarePlanStore *)store completion:(CMHRemoteSyncCompletion)block
{
    NSAssert(nil != store, @"Cannot instantiate %@ without associated %@", [self class], [CMHCarePlanStore class]);
    
    self = [super init];
    if (nil == self) { return nil; }
    
    _store = store;
    _block = block;
    self.queuePriority = NSOperationQueuePriorityHigh;
    
    return self;
}

#pragma mark Overrides

- (void)main
{
    if (self.isCancelled) {
        NSLog(@"[CMHealth] Pull Operation Cancelled");
        return;
    }
    
    __block BOOL fetchSuccess = NO;
    __block NSArray *fetchErrors = nil;
    
    cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
       [self.store runFetchWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
           fetchSuccess = success;
           fetchErrors = errors;
           done();
       }];
    });
    
    if (self.isCancelled) {
        NSLog(@"[CMHealth] Pull Operation Cancelled");
        return;
    }
    
    if (nil != self.block) {
        self.block(fetchSuccess, fetchErrors);
    }
}

@end
