#import "CMHCareSyncQueue.h"
#import "CMHCareEvent.h"
#import "CMHCareActivity.h"
#import "CMHDisptachUtils.h"
#import "CMHCareObjectSaver.h"
#import "CMHCarePushOperation.h"

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emptyQueueWithAppInBackground) name:UIApplicationWillResignActiveNotification object:nil];

    return self;
}

- (void)dealloc
{
    [_updateQueue removeObserver:self forKeyPath:@"operationCount"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark Public API

- (void)enqueueUpdateEvent:(CMHCareEvent *)event
{
    NSAssert(nil != event, @"Cannot call %s without providing a %@", __PRETTY_FUNCTION__, [CMHCareEvent class]);
    
    CMHCarePushOperation *updateOperation = [[CMHCarePushOperation alloc] initWithEvent:event];
    updateOperation.queuePriority = NSOperationQueuePriorityHigh;
    [self.updateQueue addOperation:updateOperation];
}

- (void)enqueueUpdateActivity:(CMHCareActivity *)activity
{
    NSAssert(nil != activity, @"Cannot call %s without providen a %@", __PRETTY_FUNCTION__, [CMHCareActivity class]);

    CMHCarePushOperation *updateOperation = [[CMHCarePushOperation alloc] initWithActivity:activity];
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

#pragma mark Notificatoin Handlers

- (void)emptyQueueWithAppInBackground
{
    if (0 == self.updateQueue.operationCount) {
        return;
    }

    NSLog(@"[CMHealth] Sync queue attempting to complete %li operation(s) in background", (long)self.updateQueue.operationCount);

    UIApplication *app = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"[CMHealth] Sync queue failed to complete %li operation(s) in background", (long)self.updateQueue.operationCount);

        [app endBackgroundTask:bgTaskId];
        bgTaskId = UIBackgroundTaskInvalid;
    }];

    dispatch_queue_t completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(completionQueue, ^{
        [self.updateQueue waitUntilAllOperationsAreFinished];

        NSLog(@"[CMHealth] Sync queue successfully emptied in background");
        [app endBackgroundTask:bgTaskId];
    });
}

@end
