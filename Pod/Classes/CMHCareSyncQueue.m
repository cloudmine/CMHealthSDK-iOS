#import "CMHCareSyncQueue.h"
#import "CMHCareEvent.h"
#import "CMHDisptachUtils.h"
#import "CMHCareObjectSaver.h"

@interface CMHOperation : NSOperation

@property (nonatomic, nonnull) CMHCareEvent *event;

@end

@implementation CMHOperation

- (instancetype)initWithEvent:(CMHCareEvent *)event
{
    NSAssert(nil != event, @"Cannot instantiate %@ without an object to upload", [self class]);
    
    self = [super init];
    if (nil == self || nil == event) { return nil; }
    
    _event = event;
    
    return self;
}

#pragma mark Overrides

- (void)main
{
    NSUInteger retryCount = 0;
    
    while(true) { // Retry loop
        if (self.isCancelled) {
            NSLog(@"[CMHealth] Operation cancelled");
            return;
        }
        
        __block NSString *saveStatus = nil;
        __block NSError *saveError = nil;
        
        cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
            [CMHCareObjectSaver saveCMHCareObject:self.event withCompletion:^(NSString * _Nullable status, NSError * _Nullable error) {
                saveStatus = status;
                saveError = error;
                
                done();
            }];
        });
        
        if (nil == saveStatus) {
            NSTimeInterval sleepTime = [CMHOperation sleepTimeForRetryCount:retryCount];
            retryCount += 1;
            
            NSLog(@"[CMHEALTH] Error uploading event via queue %@, retrying after: %f", saveError.localizedDescription, sleepTime);
            if (self.isCancelled) {
                NSLog(@"[CMHealth] Operation cancelled");
                return;
            }
            
            [NSThread sleepForTimeInterval:sleepTime];
        } else {
            NSLog(@"[CMHEALTH] Event uploaded via queue with status: %@", saveStatus);
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

@interface CMHCareSyncQueue ()

@property (nonatomic, nonnull) NSOperationQueue *updateQueue;

@end

@implementation CMHCareSyncQueue

#pragma mark Initialization

- (instancetype)init
{
    self = [super init];
    if (nil == self) { return nil; }

    _updateQueue = [[NSOperationQueue alloc] init];
    _updateQueue.name = @"com.cloudemineinc.CMHealth.UpdateQueue";
    _updateQueue.maxConcurrentOperationCount = 1;
    _updateQueue.qualityOfService = NSQualityOfServiceUserInitiated;

    [_updateQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];

    return self;
}

- (void)dealloc
{
    [_updateQueue removeObserver:self forKeyPath:@"operationCount"];
}

#pragma mark Public API

- (void)enqueueUpdateEvent:(CMHCareEvent *)event
{
    NSAssert(nil != event, @"Cannot call %s without providing a %@", __PRETTY_FUNCTION__, [CMHCareEvent class]);
    
    CMHOperation *updateOperation = [[CMHOperation alloc] initWithEvent:event];
    updateOperation.queuePriority = NSOperationQueuePriorityHigh;
    [self.updateQueue addOperation:updateOperation];
}

- (void)runInBackgroundAfterQueueEmpties:(void(^_Nonnull)())block
{
    NSAssert(nil != block, @"Must provide block to execute to %s", __PRETTY_FUNCTION__);

    dispatch_queue_t gcdQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(gcdQueue, ^{
        NSLog(@"[CMHealth] Waiting for update queu to empty %li operations", self.updateQueue.operationCount);
        [self.updateQueue waitUntilAllOperationsAreFinished];
        NSLog(@"[CMHealth] Update queue emptied; proceeding with block");
        block();
    });
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object == self.updateQueue && [@"operationCount" isEqualToString:keyPath] ) {
        [self operationCountChangedTo:self.updateQueue.operationCount];
    }
}

- (void)operationCountChangedTo:(NSUInteger)count
{
    NSLog(@"[CMHealth] Operation count is: %li", (long)count);
}

@end
