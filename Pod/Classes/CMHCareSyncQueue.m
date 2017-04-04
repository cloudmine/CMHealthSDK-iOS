#import "CMHCareSyncQueue.h"
#import "CMHCareEvent.h"
#import "CMHCareActivity.h"
#import "CMHDisptachUtils.h"
#import "CMHCareObjectSaver.h"
#import "CMHCarePushOperation.h"

@interface CMHCareSyncQueue ()

@property (nonatomic, nonnull) NSOperationQueue *updateQueue;
@property (nonatomic, nonnull) NSOperationQueue *afterQueue;
@property (nonatomic, readonly) BOOL isAfterQueueWaiting;
@property (nonatomic, readonly) BOOL isThereAnUpdatePending;
@property (nonatomic, nonnull) NSString *cmhIdentifier;
@property (nonatomic, nonnull, readonly) NSString *archiveKey;
@property (nonatomic, nonnull) NSNumber *preQueueCount;

@end

@implementation CMHCareSyncQueue

#pragma mark Initialization

- (instancetype)initWithCMHIdentifier:(NSString *)cmhIdentifer
{
    NSAssert(nil != cmhIdentifer, @"Cannot instantiate %@ without a cmhIdentifier");
    
    self = [super init];
    if (nil == self || nil == cmhIdentifer) { return nil; }
    
    _cmhIdentifier = [cmhIdentifer copy];
    
    _preQueueCount = @0;

    _updateQueue = [NSOperationQueue new];
    _updateQueue.name = [NSString stringWithFormat:@"com.cloudemineinc.CMHealth.UpdateQueue-%@", _cmhIdentifier];
    _updateQueue.maxConcurrentOperationCount = 1;
    _updateQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    [_updateQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    
    _afterQueue = [NSOperationQueue new];
    _afterQueue.name = [NSString stringWithFormat:@"com.cloudemineinc.CMHealth.AfterQueue-%@", _cmhIdentifier];
    _afterQueue.maxConcurrentOperationCount = 1;
    _afterQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    _afterQueue.suspended = YES;
    [_afterQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emptyQueueWithAppInBackground) name:UIApplicationWillResignActiveNotification object:nil];
    
    // The order here matters. We don't want to drop operations if the app is terminated during this initializer
    // So, we don't clear the archive until:
    // 1. Archived Ops are added to the new queue
    // 2. New queue is listening for termination notification
    // This ensures any pending operations would be re-archived before termination
    NSArray <CMHCarePushOperation *> *archivedOps = [self unarchiveOperations];
    [_updateQueue addOperations:archivedOps waitUntilFinished:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(archiveOperations) name:UIApplicationWillTerminateNotification object:nil];
    [self clearArchivedOperations];

    return self;
}

- (void)dealloc
{
    [_updateQueue removeObserver:self forKeyPath:@"operationCount"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

#pragma mark Public API

- (void)incrementPreQueueCount
{
    @synchronized (self) {
        _preQueueCount = [NSNumber numberWithInteger:(_preQueueCount.integerValue + 1)];
    }
}

- (void)decrementPreQueueCount
{
    @synchronized (self) {
        _preQueueCount = [NSNumber numberWithInteger:(_preQueueCount.integerValue - 1)];
    }
}

- (void)enqueueUpdateEvent:(CMHCareEvent *)event
{
    NSAssert(nil != event, @"Cannot call %s without providing a %@", __PRETTY_FUNCTION__, [CMHCareEvent class]);
    
    CMHCarePushOperation *updateOperation = [[CMHCarePushOperation alloc] initWithEvent:event];
    [self.updateQueue addOperation:updateOperation];
    
    [self decrementPreQueueCount];
    [self toggleQueues];
}

- (void)enqueueUpdateActivity:(CMHCareActivity *)activity
{
    NSAssert(nil != activity, @"Cannot call %s without providen a %@", __PRETTY_FUNCTION__, [CMHCareActivity class]);

    CMHCarePushOperation *updateOperation = [[CMHCarePushOperation alloc] initWithActivity:activity];
    [self.updateQueue addOperation:updateOperation];
    
    [self decrementPreQueueCount];
    [self toggleQueues];
}

- (void)runInBackgroundAfterQueueEmpties:(void(^_Nonnull)())block
{
    NSAssert(nil != block, @"Must provide block to execute to %s", __PRETTY_FUNCTION__);
    NSLog(@"[CMHealth] Waiting for update queue to empty %li operations", self.updateQueue.operationCount);
    
    [self.afterQueue addOperationWithBlock:block];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object == self.updateQueue && [@"operationCount" isEqualToString:keyPath] ) {
        [self updateQueueOperationCountChangedTo:self.updateQueue.operationCount];
    } else if(object == self.afterQueue && [@"operationCount" isEqualToString:keyPath]) {
        [self afterQueueOperationCountChangedTo:self.afterQueue.operationCount];
    }
}

- (void)updateQueueOperationCountChangedTo:(NSUInteger)count
{
    NSLog(@"[CMHealth] Update Queue Operation count is: %li", (long)count);
    [self toggleQueues];
}

- (void)afterQueueOperationCountChangedTo:(NSUInteger)count
{
    NSLog(@"[CMHealth After Queue Operation count is: %li", (long)count);
    [self toggleQueues];
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

- (void)archiveOperations
{
    self.updateQueue.suspended = YES;
    
    if (self.updateQueue.operationCount < 1) {
        return;
    }
    
    NSLog(@"[CMHealth] Sync queue archiving %li operations before termination", (long)self.updateQueue.operationCount);
    
    NSData *opsData = [NSKeyedArchiver archivedDataWithRootObject:self.updateQueue.operations];
    [[NSUserDefaults standardUserDefaults] setObject:opsData forKey:self.archiveKey];
}

#pragma mark Getters

- (NSString *)archiveKey
{
    return [NSString stringWithFormat:@"CMHQueueArchive-%@", _cmhIdentifier];
}

- (BOOL)isAfterQueueWaiting
{
    return self.afterQueue.isSuspended && self.afterQueue.operationCount > 0;
}

- (BOOL)isThereAnUpdatePending
{
    return self.updateQueue.operationCount > 0 || self.preQueueCount.integerValue > 0;
}

#pragma mark Helpers

- (void)toggleQueues
{
    @synchronized (self) {
        if (self.isAfterQueueWaiting && !self.isThereAnUpdatePending) {
            [self emptyAfterQueue];
        } else if(0 == self.afterQueue.operationCount && self.updateQueue.suspended) {
            [self suspendAfterQueue];
        }
    }
    
    // update == 0, after == 0, preQ == 0: update NO,  after YES
    // update > 0, after == 0, preQ == 0:  update NO,  after YES
    // update == 0, after > 0, preQ == 0:  update YES, after NO
    // update == 0, after == 0, preQ > 0:  update NO,  after YES
    // update > 0, after > 0, preQ == 0:   update NO,  after YES
    // update > 0, after == 0, preQ > 0:   update NO,  after YES
    // update == 0, after > 0, preQ > 0:   udpate NO,  after YES
    // update > 0, after > 0, preQ > 0:    update NO,  after YES
}

- (void)emptyAfterQueue
{
    NSLog(@"[CMHealth] Empyting the After-Update queue containing %li operations", (long)self.afterQueue.operationCount);
    
    self.updateQueue.suspended = YES;
    self.afterQueue.suspended = NO;
}

- (void)suspendAfterQueue
{
    NSLog(@"[CMHealth] Suspending the after queue");
    
    self.afterQueue.suspended = YES;
    self.updateQueue.suspended = NO;
}

- (NSArray *)unarchiveOperations
{
    NSData *opsData = [[NSUserDefaults standardUserDefaults] objectForKey:self.archiveKey];
    if (nil == opsData) {
        return @[];
    }
    
    NSArray *ops = [NSKeyedUnarchiver unarchiveObjectWithData:opsData];
    NSLog(@"[CMHealth] Sync queue restoring %li unarchived operations", (long)ops.count);
    
    return ops;
}

- (void)clearArchivedOperations
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.archiveKey];
}

@end
