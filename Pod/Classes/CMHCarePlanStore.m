#import "CMHCarePlanStore.h"
#import "OCKCarePlanEvent+CMHealth.h"

@interface CMHCarePlanStore ()<OCKCarePlanStoreDelegate>

@property (nonatomic, weak) id<OCKCarePlanStoreDelegate> passDelegate;

@end

@implementation CMHCarePlanStore

#pragma MARK Initialization

- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)URL
{
    NSAssert(false, @"-initWithPerasistenceDirectoryURL: is unavailable for CMHCarePlanStore, use +storeWithPersistenceDirectoryURL:");
    return nil;
}

- (instancetype)_initWithPersistenceDirectoryURL:(NSURL *)URL
{
    return [super initWithPersistenceDirectoryURL:URL];
}

+ (instancetype)storeWithPersistenceDirectoryURL:(NSURL *)URL
{
    CMHCarePlanStore *store = [[CMHCarePlanStore alloc] _initWithPersistenceDirectoryURL:URL];
    store.delegate = nil;
    
    return store;
}

#pragma MARK Setters/Getters

- (id<OCKCarePlanStoreDelegate>)delegate
{
    return _passDelegate;
}

- (void)setDelegate:(id<OCKCarePlanStoreDelegate>)delegate
{
    [super setDelegate:self];
    _passDelegate = delegate;
}

#pragma MARK OCKCarePlanStoreDelegate

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event
{
    if (nil != _passDelegate && [_passDelegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvent:)]) {
        [_passDelegate carePlanStore:store didReceiveUpdateOfEvent:event];
    }
    
    [event cmh_saveWithCompletion:^(NSString * _Nullable uploadStatus, NSError * _Nullable error) {
        if (nil == uploadStatus) {
            NSLog(@"[CMHealth] Error uploading event: %@", error.localizedDescription);
            return;
        }
        
        NSLog(@"[CMHealth] Event uploaded with status: %@", uploadStatus);
    }];
}

- (void)carePlanStoreActivityListDidChange:(OCKCarePlanStore *)store
{
    if (nil != _passDelegate && [_passDelegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
        [_passDelegate carePlanStoreActivityListDidChange:store];
    }
}

@end
