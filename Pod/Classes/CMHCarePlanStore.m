#import "CMHCarePlanStore.h"
#import "OCKCarePlanEvent+CMHealth.h"
#import "CMHCarePlanStore_internal.h"
#import "CMHInternalUser.h"
#import "CMHCareActivity.h"
#import "CMHErrorUtilities.h"

@interface CMHCarePlanStore ()<OCKCarePlanStoreDelegate>

@property (nonatomic, weak) id<OCKCarePlanStoreDelegate> passDelegate;
@property (nonatomic, nonnull) NSString *cmhIdentifier;

@end

@implementation CMHCarePlanStore

#pragma mark Initialization

- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)URL
{
    NSAssert(false, @"-initWithPerasistenceDirectoryURL: is unavailable for CMHCarePlanStore, use +storeWithPersistenceDirectoryURL:");
    return nil;
}

- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)URL andCMHIdentifier:(NSString *)cmhIdentifier
{
    NSAssert(nil != cmhIdentifier, @"Cannot instantiate %@ without a CMHIdentifier- the object id of the user whose data is being stored", [self class]);
    
    self = [super initWithPersistenceDirectoryURL:URL];
    if (nil == self) { return nil; }
    
    _cmhIdentifier = [cmhIdentifier copy];
    
    return self;
}

+ (instancetype)storeWithPersistenceDirectoryURL:(NSURL *)URL
{
    NSString *currentUserId = [CMHInternalUser currentUser].objectId;
    NSAssert(nil != currentUserId, @"The patient must be signed in before accessing their %@", [self class]);
    
    CMHCarePlanStore *store = [[CMHCarePlanStore alloc] initWithPersistenceDirectoryURL:URL andCMHIdentifier:currentUserId];
    store.delegate = nil;
    
    return store;
}

#pragma mark Setters/Getters

- (id<OCKCarePlanStoreDelegate>)delegate
{
    return _passDelegate;
}

- (void)setDelegate:(id<OCKCarePlanStoreDelegate>)delegate
{
    [super setDelegate:self];
    _passDelegate = delegate;
}

#pragma mark Overrides

- (void)addActivity:(OCKCarePlanActivity *)activity completion:(void (^)(BOOL, NSError * _Nullable))completion
{
    [super addActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
        completion(success, error);
        
        if (!success) {
            return;
        }
        
        CMHCareActivity *cmhActivity = [[CMHCareActivity alloc] initWithActivity:activity andUserId:self.cmhIdentifier];
        
        [cmhActivity saveWithUser:[CMStore defaultStore].user callback:^(CMObjectUploadResponse *response) {
            NSError *saveError = [CMHErrorUtilities errorForUploadWithObjectId:cmhActivity.objectId uploadResponse:response];
            if (nil != saveError) {
                NSLog(@"[CMHealth] Error uploading activity: %@", error.localizedDescription);
                return;
            }
            
            NSLog(@"[CMHealth] Activity uploaded with status: %@", response.uploadStatuses[cmhActivity.objectId]);
        }];
    }];
}

- (void)setEndDate:(NSDateComponents *)endDate
       forActivity:(OCKCarePlanActivity *)activity
        completion:(void (^)(BOOL, OCKCarePlanActivity * _Nullable, NSError * _Nullable))completion
{
    [super setEndDate:endDate forActivity:activity completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
        
        completion(success, activity, error);
        
        if (!success) {
            return;
        }
        
        // TODO: Queue update to activity
    }];
}

- (void)removeActivity:(OCKCarePlanActivity *)activity
            completion:(void (^)(BOOL, NSError * _Nullable))completion
{
    [super removeActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
        
        completion(success, error);
        
        if (!success) {
            return;
        }
        
        // TODO: Queue update to activity
    }];
}

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
        
        [event cmh_saveWithUserId:self.cmhIdentifier completion:^(NSString * _Nullable uploadStatus, NSError * _Nullable error) {
            if (nil == uploadStatus) {
                NSLog(@"[CMHealth] Error uploading event: %@", error.localizedDescription);
                return;
            }
            
            NSLog(@"[CMHealth] Event uploaded with status: %@", uploadStatus);
        }];
    }];
}

#pragma mark OCKCarePlanStoreDelegate

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
