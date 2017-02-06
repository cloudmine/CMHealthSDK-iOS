#import "CMHCarePlanStore.h"
#import "OCKCarePlanEvent+CMHealth.h"
#import "CMHCarePlanStore_internal.h"
#import "CMHInternalUser.h"
#import "CMHCareActivity.h"
#import "CMHCareEvent.h"
#import "CMHErrorUtilities.h"
#import "CMHDisptachUtils.h"

@interface CMHCarePlanStore ()<OCKCarePlanStoreDelegate>

@property (nonatomic, weak) id<OCKCarePlanStoreDelegate> passDelegate;
@property (nonatomic, nonnull) NSString *cmhIdentifier;

@property (nonatomic, nonnull) dispatch_group_t updateGroup;
@property (nonatomic, nullable) CMHCareEvent *eventBeingUpdated;

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
    _updateGroup = dispatch_group_create();
    
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

#pragma mark Public CM API

- (void)fetchEventsTestOld
{
    CMStoreOptions *noLimitOption = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:-1]];
    
    [[CMStore defaultStore] allUserObjectsOfClass:[CMHCareEvent class] additionalOptions:noLimitOption callback:^(CMObjectFetchResponse *response) { // TODO: Use __update__ based query
        NSError *fetchError = [CMHErrorUtilities errorForFetchWithResponse:response];
        if (nil != fetchError) {
            NSLog(@"[CMHEALTH] Error fetching events: %@", fetchError.localizedDescription);
            return;
        }
        
        NSArray <CMHCareEvent *> *wrappedEvents = response.objects;
        
        for (CMHCareEvent *cEvent in wrappedEvents) {
            [self eventsForActivity:cEvent.activity date:cEvent.date completion:^(NSArray<OCKCarePlanEvent *> * _Nonnull storeEvents, NSError * _Nullable fetchStoreError) {
                if (nil != fetchStoreError) {
                    NSLog(@"[CMHEALTH] Error fetching event %@ from store: %@", cEvent, fetchStoreError.localizedDescription);
                    return;
                }
                
                for (OCKCarePlanEvent *sEvent in storeEvents) {
                    BOOL isCorrectOccurence = sEvent.occurrenceIndexOfDay == cEvent.occurrenceIndexOfDay;
                    BOOL isIdenticalToStore = [cEvent isDataEquivalentOf:sEvent];
                    
                    if (!isCorrectOccurence || isIdenticalToStore) {
                        continue;
                    }
                    
                    self.eventBeingUpdated = cEvent;
    
                    cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                        [super updateEvent:sEvent withResult:cEvent.result state:cEvent.state completion:^(BOOL success, OCKCarePlanEvent * _Nullable updatedEvent, NSError * _Nullable updateStoreError) {
                            if (nil != updateStoreError) {
                                NSLog(@"[CMHEALTH] Error updating event %@ in store:", updatedEvent, updateStoreError);
                                //done();
                                return;
                            }
                            
                            NSLog(@"[CMHEALTH] Successfully updated event in store: %@", updatedEvent);
                            done();
                        }];
                   });
                    
                    self.eventBeingUpdated = nil;
                }
            }];
        }
    }];
}

- (void)fetchEventsTest
{
    CMStoreOptions *noLimitOption = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:-1]];
    
    [[CMStore defaultStore] allUserObjectsOfClass:[CMHCareEvent class] additionalOptions:noLimitOption callback:^(CMObjectFetchResponse *response) {
        NSError *fetchError = [CMHErrorUtilities errorForFetchWithResponse:response];
        if (nil != fetchError) {
//            if (nil != block) {
//                block(NO, @[fetchError]);
//            }
            return;
        }
        
        NSArray <CMHCareEvent *> *wrappedEvents = response.objects;
        
        dispatch_queue_t updateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(updateQueue, ^{
            NSMutableArray<NSError *> *updateErrors = [NSMutableArray new];
            
            for (CMHCareEvent *wrappedEvent in wrappedEvents) {
                __block NSArray<OCKCarePlanEvent *> *storeEvents = nil;
                __block NSError *storeError = nil;
                
                cmh_wait_until(^(CMHDoneBlock _Nonnull done) {
                    [self eventsForActivity:wrappedEvent.activity date:wrappedEvent.date completion:^(NSArray<OCKCarePlanEvent *> * _Nonnull events, NSError * _Nullable error) {
                        storeEvents = events;
                        storeError = error;
                        done();
                    }];
                });
                
                if (nil != storeError) {
                    [updateErrors addObject:storeError];
                    continue;
                }
                
                for (OCKCarePlanEvent *anEvent in storeEvents) {
                    if (anEvent.occurrenceIndexOfDay != wrappedEvent.occurrenceIndexOfDay ||
                        [wrappedEvent isDataEquivalentOf:anEvent]) {
                        continue;
                    }
                    
                    __block NSError *updateStoreError = nil;
                    __block OCKCarePlanEvent *updatedEvent = nil;
                    
                    self.eventBeingUpdated = wrappedEvent;
                    
                    dispatch_group_enter(self.updateGroup);
                    
                    cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                        [super updateEvent:anEvent withResult:wrappedEvent.result state:wrappedEvent.state completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
                            updateStoreError = error;
                            updatedEvent = event;
                            done();
                        }];
                    });
                    
                    if (nil != updateStoreError) {
                        NSLog(@"[CMHEALTH] Error updating event %@ in store:", updatedEvent, updateStoreError);
                        [updateErrors addObject:updateStoreError];
                        dispatch_group_leave(self.updateGroup);
                    }
                    
                    dispatch_group_wait(self.updateGroup, DISPATCH_TIME_FOREVER);
                    
                    self.eventBeingUpdated = nil;
                    
                    NSLog(@"[CMHEALTH] Successfully updated event in store: %@", updatedEvent);
                }
            }
            
//            if (nil == block) {
//                return;
//            }
            
            BOOL success = updateErrors.count < 1;
//            block(success, [updateErrors copy]);
        });
    }];
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
    if (nil != self.eventBeingUpdated && [self.eventBeingUpdated isDataEquivalentOf:event]) {
        dispatch_group_leave(self.updateGroup);
        return;
    }
    
    if (nil == _passDelegate || ![_passDelegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvent:)]) {
        return;
    }
    
    [_passDelegate carePlanStore:store didReceiveUpdateOfEvent:event];
}

- (void)carePlanStoreActivityListDidChange:(OCKCarePlanStore *)store
{
    if (nil != _passDelegate && [_passDelegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
        [_passDelegate carePlanStoreActivityListDidChange:store];
    }
}

@end
