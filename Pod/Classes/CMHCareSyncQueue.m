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
    if (self.cancelled) {
        return;
    }
    
    cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
        [CMHCareObjectSaver saveCMHCareObject:self.event withCompletion:^(NSString * _Nullable status, NSError * _Nullable saveError) {
            
            if (nil != saveError) {
                NSLog(@"[CMHEALTH] Error uploading event via queue: %@", saveError.localizedDescription);
            } else {
                NSLog(@"[CMHEALTH] Event uploaded via queue with status: %@", status);
            }
            
            done();
            
            //TODO: Handle failure/retries
        }];
    });
}


@end

@interface CMHCareSyncQueue ()

@property (nonatomic, nonnull) NSOperationQueue *updateQueue;

@end

@implementation CMHCareSyncQueue

+ (instancetype)sharedQueue
{
    static dispatch_once_t onceToken;
    static CMHCareSyncQueue *queue = nil;
    
    dispatch_once(&onceToken, ^{
        queue = [[self alloc] initInternal];
    });
    
    return queue;
}

- (instancetype)init
{
    @throw @"%s Unavailable, call + sharedQueue";
}

- (instancetype)initInternal
{
    self = [super init];
    if (nil == self) { return nil; }
    
    _updateQueue = [[NSOperationQueue alloc] init];
    _updateQueue.name = @"com.cloudemineinc.CMHealth.UpdateQueue";
    _updateQueue.maxConcurrentOperationCount = 1;
    _updateQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    
    return self;
}

#pragma mark Public API

- (void)enqueueUpdateEvent:(CMHCareEvent *)event
{
    NSAssert(nil != event, @"Cannot call %s without providing a %@", __PRETTY_FUNCTION__, [CMHCareEvent class]);
    
    CMHOperation *updateOperation = [[CMHOperation alloc] initWithEvent:event];
    [self.updateQueue addOperation:updateOperation];
}

@end
