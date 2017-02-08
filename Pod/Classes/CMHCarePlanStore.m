#import "CMHCarePlanStore.h"
#import "OCKCarePlanEvent+CMHealth.h"
#import "CMHCarePlanStore_internal.h"
#import "CMHInternalUser.h"
#import "CMHCareActivity.h"
#import "CMHCareEvent.h"
#import "CMHErrorUtilities.h"
#import "CMHDisptachUtils.h"

static NSString * const _Nonnull CMInternalUpdatedKey = @"__updated__";
static NSString * const _Nonnull CMHEventSyncKeyPrefix = @"CMHEventSync-";

@interface CMHCarePlanStore ()<OCKCarePlanStoreDelegate>

@property (nonatomic, weak) id<OCKCarePlanStoreDelegate> passDelegate;
@property (nonatomic, nonnull) NSString *cmhIdentifier;

@property (nonatomic, nonnull) dispatch_group_t updateGroup;
@property (nonatomic, nullable) CMHCareEvent *eventBeingUpdated;
@property (nonatomic) BOOL isUpdatingActivity; // Can only do a flag because delegate callback does not include activity info; could drop 'real' activity updates

@property (nonatomic, nonnull) NSDateFormatter *cmTimestampFormatter;
@property (nonatomic, nonnull, readonly) NSString *eventSyncKey;
@property (nonatomic, nonnull, readonly) NSString *eventLastSyncStamp;

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
    _isUpdatingActivity = NO;
    
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

- (void)syncFromRemoteWithCompletion:(CMHRemoteSyncCompletion)block
{
    [self syncRemoteActivitiesWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
        if (!success) {
            NSLog(@"[CMHEALTH] Error syncing activities: %@", errors);
            
            if (nil != block) {
                block(NO, errors);
            }
            return;
        }
        
        
        NSLog(@"[CMHEALTH] Successful sync of activities");
        
        [self syncRemoteEventsWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
            if (!success) {
                NSLog(@"[CMHEALTH] Error syncing events: %@", errors);
                
                if (nil != block) {
                    block(NO, errors);
                }
                return;
            }
            
            NSLog(@"[CMHEALTH] Successful sync of events");
            block(YES, @[]);
        }];
    }];
}

- (void)clearLocalStore
{
    NSArray *errors = [self clearLocalStoreDataSynchronously];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.eventSyncKey];
    
    if (errors.count > 0) {
        NSLog(@"[CMHEALTH] There were %li errors clearing the local store: %@", (long)errors.count, errors);
    } else {
        NSLog(@"[CMHEALTH] Successfully flushed the local store");
    }
}

- (NSString *)timestampForDate:(NSDate *)date
{
    return [self.cmTimestampFormatter stringFromDate:date];
}

- (void)syncRemoteEventsWithCompletion:(CMHRemoteSyncCompletion)block;
{
    CMStoreOptions *noLimitOption = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:-1]];
    NSString *query = [NSString stringWithFormat:@"[%@ = \"%@\", %@ > \"%@\"]", CMInternalClassStorageKey, [CMHCareEvent class], CMInternalUpdatedKey, self.eventLastSyncStamp];
    NSDate *syncStartTime = [NSDate new];
    
    [[CMStore defaultStore] searchUserObjects:query additionalOptions:noLimitOption callback:^(CMObjectFetchResponse *response) {
        NSError *fetchError = [CMHErrorUtilities errorForFetchWithResponse:response];
        if (nil != fetchError) {
            if (nil != block) {
                block(NO, @[fetchError]);
            }
            return;
        }
        
        NSArray <CMHCareEvent *> *wrappedEvents = response.objects;
        
        dispatch_queue_t updateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(updateQueue, ^{
            NSMutableArray<NSError *> *updateErrors = [NSMutableArray new];
            
            for (CMHCareEvent *wrappedEvent in wrappedEvents) {
                __block NSError *updateStoreError = nil;
                __block OCKCarePlanEvent *updatedEvent = nil;
                
                self.eventBeingUpdated = wrappedEvent;
                
                dispatch_group_enter(self.updateGroup);
                
                cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                    [super updateEvent:wrappedEvent.ckEvent withResult:wrappedEvent.ckEvent.result state:wrappedEvent.ckEvent.state completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
                        updateStoreError = error;
                        updatedEvent = event;
                        done();
                    }];
                });
                
                if (nil != updateStoreError) {
                    NSLog(@"[CMHEALTH] Error updating event %@ in store:", updatedEvent, updateStoreError);
                    [updateErrors addObject:updateStoreError];
                    dispatch_group_leave(self.updateGroup);
                    self.eventBeingUpdated = nil;
                    continue;
                }
                
                dispatch_group_wait(self.updateGroup, DISPATCH_TIME_FOREVER);
                    
                self.eventBeingUpdated = nil;
                [self saveEventLastSyncTime:syncStartTime];
                
                NSLog(@"[CMHEALTH] Successfully updated event in store: %@", updatedEvent);
            }
            
            if (nil == block) {
                return;
            }
            
            BOOL success = updateErrors.count < 1;
            block(success, [updateErrors copy]);
        });
    }];
}

- (void)syncRemoteActivitiesWithCompletion:(nullable CMHRemoteSyncCompletion)block;
{
    CMStoreOptions *noLimitOption = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:-1]];

    [[CMStore defaultStore] allUserObjectsOfClass:[CMHCareActivity class] additionalOptions:noLimitOption callback:^(CMObjectFetchResponse *response) {
        NSError *fetchError = [CMHErrorUtilities errorForFetchWithResponse:response];
        if (nil != fetchError) {
            if (nil != block) {
                block(NO, @[fetchError]);
            }
            return;
        }
        
        NSArray <CMHCareActivity *> *wrappedActivities = response.objects;
        
        dispatch_queue_t updateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(updateQueue, ^{
            NSMutableArray<NSError *> *updateErrors = [NSMutableArray new];
            
            __block BOOL storeSuccess = NO;
            __block NSArray<OCKCarePlanActivity *> *storeActivities = nil;
            __block NSError *storeError = nil;
            
            cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                [super activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nullable error) {
                    storeSuccess = success;
                    storeActivities = activities;
                    storeError = error;
                    
                    done();
                }];
            });
            
            if (!storeSuccess) {
                if (nil != storeError) {
                    [updateErrors addObject:storeError];
                }
                
                if (nil != block) {
                    block(NO, [updateErrors copy]);
                }
                
                return;
            }
            
            for (CMHCareActivity *wrappedActivity in wrappedActivities) {
                OCKCarePlanActivity *storeActivity = [CMHCarePlanStore activityWithIdentifier:wrappedActivity.ckActivity.identifier from:storeActivities];
                
                if (nil == storeActivity) {
                    __block BOOL updateStoreSuccess = NO;
                    __block NSError *updateStoreError = nil;
                    
                    dispatch_group_enter(self.updateGroup);
                    self.isUpdatingActivity = YES;
                    
                    cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                        [super addActivity:wrappedActivity.ckActivity completion:^(BOOL success, NSError * _Nullable error) {
                            updateStoreSuccess = success;
                            updateStoreError = error;
                            done();
                        }];
                    });
                    
                    if (!updateStoreSuccess) {
                        if (nil != updateStoreError) {
                            [updateErrors addObject:updateStoreError];
                        }
                        
                        NSLog(@"[CMHEALTH] Error adding fetched activity %@ to store: %@", wrappedActivity.ckActivity, updateStoreError.localizedDescription);
                        dispatch_group_leave(self.updateGroup);
                        self.isUpdatingActivity = NO;
                        continue; // Continue? Or totally stop? o_O
                    }
                    
                    dispatch_group_wait(self.updateGroup, DISPATCH_TIME_FOREVER);
                    
                    self.isUpdatingActivity = NO;
                    NSLog(@"[CMHEALTH] Fetched and added new activity to store: %@", wrappedActivity.ckActivity);
                    
                } else if([wrappedActivity.ckActivity isEqual:storeActivity]) {
                    NSLog(@"[CMHEALTH] Skipping fetched activity that is already in store: %@", wrappedActivity.ckActivity);
                    continue;
                } else if(![wrappedActivity.ckActivity.schedule isEqual:storeActivity.schedule]) {
                    NSLog(@"[CMHEALTH] Fetched activity with updated schedule (end date): %@", wrappedActivity.ckActivity);
                    // Set end date in store
                }
            }
            
            if (nil == block) {
                return;
            }
            
            BOOL success = updateErrors.count < 1;
            block(success, [updateErrors copy]);
        });
    }];
}

+ (nullable OCKCarePlanActivity *)activityWithIdentifier:(nonnull NSString *)identifier from:(nonnull NSArray<OCKCarePlanActivity *>*)activities
{
    for (OCKCarePlanActivity *activity in activities) {
        if ([activity.identifier isEqualToString:identifier]) {
            return activity;
        }
    }
    
    return nil;
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

- (NSDateFormatter *)cmTimestampFormatter
{
    if (nil == _cmTimestampFormatter) {
        _cmTimestampFormatter = [NSDateFormatter new];
        _cmTimestampFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
        _cmTimestampFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _cmTimestampFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    }
    
    return _cmTimestampFormatter;
}

- (NSString *)eventSyncKey
{
    return [NSString stringWithFormat:@"%@%@", CMHEventSyncKeyPrefix, self.cmhIdentifier];
}

- (NSString *)eventLastSyncStamp
{
    NSString *savedStamp = [[NSUserDefaults standardUserDefaults] objectForKey:self.eventSyncKey];
    
    if (nil == savedStamp) {
        NSDate *longAgo = [NSDate dateWithTimeIntervalSince1970:0];
        return [self.cmTimestampFormatter stringFromDate:longAgo];
    }
    
    return savedStamp;
}

- (void)saveEventLastSyncTime:(NSDate *)date
{
    NSAssert(nil != date, @"Must provide NSDate to -saveEventLastSyncTime:");
    
    NSString *stamp = [self timestampForDate:date];
    [[NSUserDefaults standardUserDefaults] setObject:stamp forKey:self.eventSyncKey];
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
    if (nil != self.eventBeingUpdated && [self.eventBeingUpdated.ckEvent isEqual:event]) {
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
    if (self.isUpdatingActivity) {
        self.isUpdatingActivity = NO;
        dispatch_group_leave(self.updateGroup);
        return;
    }
    
    if (nil != _passDelegate && [_passDelegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
        [_passDelegate carePlanStoreActivityListDidChange:store];
    }
}

# pragma mark Helpers

- (NSArray<NSError *> *_Nonnull)clearLocalStoreDataSynchronously
{
    __block NSArray *allActivities = nil;
    __block NSError *fetchError = nil;
    __block BOOL fetchSuccess = NO;
    
    cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
        [self activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nullable error) {
            fetchSuccess = success;
            allActivities = activities;
            fetchError = error;
            done();
        }];
    });
    
    if (nil != fetchError) {
        return @[fetchError];
    }
    
    NSMutableArray *mutableErrors = [NSMutableArray new];
    
    for (OCKCarePlanActivity *activity in allActivities) {
        cmh_wait_until(^(CMHDoneBlock _Nonnull done) {
            [super removeActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
                if (!success) {
                    [mutableErrors addObject:error];
                    done();
                    return;
                }
                
                done();
            }];
        });
    }
    
    return [mutableErrors copy];
}

@end
