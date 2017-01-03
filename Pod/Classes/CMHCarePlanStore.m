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

#pragma MARK Overrides

- (void)updateEvent:(OCKCarePlanEvent *)event
         withResult:(OCKCarePlanEventResult *)result
              state:(OCKCarePlanEventState)state
         completion:(void (^)(BOOL, OCKCarePlanEvent * _Nullable, NSError * _Nullable))completion
{
    [super updateEvent:event withResult:result state:state completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
        // Pass results regardless of outcome
        completion(success, event, error);
        
        if (!success) {
            return;
        }
        
        [event cmh_saveWithCompletion:^(NSString * _Nullable uploadStatus, NSError * _Nullable error) {
            if (nil == uploadStatus) {
                NSLog(@"[CMHealth] Error uploading event: %@", error.localizedDescription);
                return;
            }
            
            NSLog(@"[CMHealth] Event uploaded with status: %@", uploadStatus);
        }];
    }];
}

#pragma MARK OCKCarePlanStoreDelegate

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event
{
    if (nil != _passDelegate && [_passDelegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvent:)]) {
        [_passDelegate carePlanStore:store didReceiveUpdateOfEvent:event];
    }
}

- (void)carePlanStoreActivityListDidChange:(OCKCarePlanStore *)store
{
    if (nil != _passDelegate && [_passDelegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
        [_passDelegate carePlanStoreActivityListDidChange:store];
    }
}

@end
