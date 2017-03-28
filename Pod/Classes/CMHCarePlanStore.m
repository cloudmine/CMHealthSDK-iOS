#import "CMHCarePlanStore.h"
#import "OCKCarePlanEvent+CMHealth.h"
#import "CMHCarePlanStore_internal.h"
#import "CMHInternalUser.h"
#import "CMHCareActivity.h"
#import "CMHCareEvent.h"
#import "CMHErrorUtilities.h"
#import "CMHDisptachUtils.h"
#import "CMHConstants_internal.h"
#import "CMHCareObjectSaver.h"
#import "CMHConfiguration.h"
#import "CMHInternalProfile.h"
#import "CMHCareSyncQueue.h"
#import "CMHCarePlanStoreVendor.h"

static NSString * const _Nonnull CMInternalUpdatedKey = @"__updated__";
static NSString * const _Nonnull CMHEventSyncKeyPrefix = @"CMHEventSync-";
static NSString * const _Nonnull CMHActivitySyncKeyPrefix = @"CMHActivitySync-";

@interface CMHCarePlanStore ()<OCKCarePlanStoreDelegate>

@property (nonatomic, weak) id<OCKCarePlanStoreDelegate> passDelegate;
@property (nonatomic, nonnull) NSString *cmhIdentifier;

@property (nonatomic, nonnull) dispatch_group_t updateGroup;
@property (nonatomic, nullable) CMHCareEvent *eventBeingUpdated;
@property (nonatomic) BOOL isUpdatingActivity; // Can only do a flag because delegate callback does not include activity info; could drop 'real' activity updates

@property (nonatomic, nonnull) NSDateFormatter *cmTimestampFormatter;
@property (nonatomic, nonnull, readonly) NSString *eventSyncKey;
@property (nonatomic, nonnull, readonly) NSString *eventLastSyncStamp;
@property (nonatomic, nonnull, readonly) NSString *activitySyncKey;
@property (nonatomic, nonnull, readonly) NSString *activityLastSyncStamp;

@property (nonatomic, nonnull) CMHCareSyncQueue *syncQueue;

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
    _syncQueue = [[CMHCareSyncQueue alloc] initWithCMHIdentifier:_cmhIdentifier];
    
    // ensures our subclass is set up as super's delegate
    _passDelegate = nil;
    [super setDelegate:self];
    
    return self;
}

+ (instancetype)storeWithPersistenceDirectoryURL:(NSURL *)URL
{
    // TODO: Asserting for a currently logged in user should be moved to the base initializer, but before we
    // can do this, we have to decide if admin users are going to CMHInternalUsers or not, right?
    NSString *currentUserId = [CMHInternalUser currentUser].objectId;
    NSAssert(nil != currentUserId, @"A user must be signed in before accessing the %@", [self class]);
    
    return [self storeWithPersistenceDirectoryURL:URL andCMHIdentifier:currentUserId];
}

+ (instancetype)storeWithPersistenceDirectoryURL:(NSURL *)URL andCMHIdentifier:(NSString *)cmhIdentifier
{
    NSAssert(nil != [CMHConfiguration sharedConfiguration].sharedObjectUpdateSnippetName, @"Must configure a Shared Object Update Snippet Name for shared care plan objects via +[CMHealth  setAppIdentifier: appSecret: sharedUpdateSnippetName:] before utitlizing %@", [self class]);
    NSAssert(nil != cmhIdentifier, @"Must provide a patient user identifier when intitializing %@", [self class]);
    
    return [[CMHCarePlanStoreVendor sharedVendor] storeForCMHIdentifier:cmhIdentifier atDirectory:URL];
}

#pragma mark Public CM API

- (void)syncFromRemoteWithCompletion:(CMHRemoteSyncCompletion)block
{
    __weak typeof(self) weakSelf = self;

    [self.syncQueue runInBackgroundAfterQueueEmpties:^{
        [weakSelf syncRemoteActivitiesWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
            if (!success) {
                NSLog(@"[CMHEALTH] Error syncing activities: %@", errors);

                if (nil != block) {
                    block(NO, errors);
                }
                return;
            }


            NSLog(@"[CMHEALTH] Successful sync of activities");

            [weakSelf syncRemoteEventsWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
                if (!success) {
                    NSLog(@"[CMHEALTH] Error syncing events: %@", errors);

                    if (nil != block) {
                        block(NO, errors);
                    }
                    return;
                }

                NSLog(@"[CMHEALTH] Successful sync of events");
                if (nil != block) {
                    block(YES, @[]);
                }
            }];
        }];
    }];
}

- (void)clearLocalStore
{
    NSArray *errors = [self clearLocalStoreDataSynchronously];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.eventSyncKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.activitySyncKey];
    
    if (errors.count > 0) {
        NSLog(@"[CMHEALTH] There were %li errors clearing the local store: %@", (long)errors.count, errors);
    } else {
        NSLog(@"[CMHEALTH] Successfully flushed the local store");
    }
}

+ (void)fetchAllPatientsWithCompletion:(CMHFetchPatientsCompletion)block
{
    NSAssert(nil != block, @"Cannot call %@ without completion block parameter", __PRETTY_FUNCTION__);
    
    dispatch_queue_t highQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(highQueue, ^{
        __block NSArray *allUsers = nil;
        __block NSDictionary *userErrors = nil;
        
        cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
            CMStoreOptions *noLimit = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:517]];
            [CMUser allUserWithOptions:noLimit callback:^(CMObjectFetchResponse *response) {
                allUsers = response.objects;
                
                NSMutableArray *mutableErrors = [NSMutableArray new];
                
                if (response.objectErrors.allValues.count > 0) {
                    [mutableErrors addObjectsFromArray:response.objectErrors.allValues];
                }
                
                if (nil != response.error) {
                    [mutableErrors addObject:response.error];
                }
                
                userErrors = [mutableErrors copy];
                
                done();
            }];
        });
        
        if (nil != userErrors && userErrors.count > 0) {
            block(NO, @[], userErrors.allValues);
            return;
        }
        
        __block NSArray *allProfiles = @[];
        __block NSError *profilesError = nil;
        
        cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
            CMStoreOptions *noLimitSharedOption = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:-1]];
            noLimitSharedOption.shared = YES;
            
            NSString *query = [NSString stringWithFormat:@"[%@ = \"%@\"]", CMInternalClassStorageKey, [CMHInternalProfile class]];
            [[CMStore defaultStore] searchUserObjects:query additionalOptions:noLimitSharedOption callback:^(CMObjectFetchResponse *response) {
                profilesError = [CMHErrorUtilities errorForFetchWithResponse:response];
                allProfiles = response.objects;
                done();
            }];
        });
        
        if (nil != profilesError) {
            block(NO, @[], @[profilesError]);
            return;
        }
        
        NSMutableArray<OCKPatient *> *mutablePatients = [NSMutableArray new];
        
        for (CMUser *user in allUsers) {
            NSAssert([user isKindOfClass:[CMUser class]], @"Expected CMUser but got %@", [user class]);
            if (![user isKindOfClass:[CMHInternalUser class]]) {
                continue;
            }
            
            // TODO: CMH Users? Filter admins
            
            NSURL *patientDir = [CMHCarePlanStore persistenceDirectoryNamed:user.objectId];
            __block CMHCarePlanStore *patientStore = nil;
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                patientStore = [CMHCarePlanStore storeWithPersistenceDirectoryURL:patientDir andCMHIdentifier:user.objectId];
            });
            
            __block BOOL syncSuccess = NO;
            __block NSArray<NSError *> *syncErrors = nil;
            
            cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                [patientStore syncFromRemoteWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
                    syncSuccess = success;
                    syncErrors = errors;
                    done();
                }];
            });
            
            if (!syncSuccess) {
                if (nil != syncErrors) {
                    block(NO, @[], syncErrors);
                } else {
                    block(NO, @[], @[]);
                }
                
                return;
            }
            
            NSString *patientName = user.email;
            NSString *patientDetail = nil;
            CMHInternalProfile *profile = [CMHCarePlanStore profileForUser:(CMHInternalUser *)user from:allProfiles];
            
            if (nil != profile) {
                NSString *fullName = nil;
                
                if (nil != profile.givenName && nil != profile.familyName) {
                    fullName = [NSString stringWithFormat:@"%@ %@", profile.givenName, profile.familyName];
                } else if (nil != profile.familyName) {
                    fullName = profile.familyName;
                } else if (nil != profile.givenName) {
                    fullName = profile.givenName;
                }
                
                if (nil != fullName) {
                    patientName = fullName;
                    patientDetail = user.email;
                }
            }
            
            OCKPatient *patient = [[OCKPatient alloc] initWithIdentifier:user.objectId
                                                           carePlanStore:patientStore
                                                                    name:patientName
                                                              detailInfo:patientDetail
                                                        careTeamContacts:nil
                                                               tintColor:nil
                                                                monogram:nil
                                                                   image:nil
                                                              categories:nil];
            [mutablePatients addObject:patient];
        }
        
        block(YES, [mutablePatients copy], @[]);
    });
}

+ (nullable CMHInternalProfile *)profileForUser:(nonnull CMHInternalUser *)user from:(nonnull NSArray<CMHInternalProfile *> *)profiles
{
    NSAssert(nil != user && nil != profiles, @"%@ called without a user and profiles array", __PRETTY_FUNCTION__);
    
    for (CMHInternalProfile *profile in profiles) {
        if (![profile isKindOfClass:[CMHInternalProfile class]]) {
            NSAssert(false, @"Expecting an array of %@'s, but found a: %@", [CMHInternalProfile class], [profile class]);
            continue;
        }
        
        if ([user.profileId isEqualToString:profile.objectId]) {
            return profile;
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
        return [self timestampForDate:longAgo];
    }
    
    return savedStamp;
}

- (NSString *)activitySyncKey
{
    return [NSString stringWithFormat:@"%@%@", CMHActivitySyncKeyPrefix, self.cmhIdentifier];
}

- (NSString *)activityLastSyncStamp
{   
    NSString *savedStamp = [[NSUserDefaults standardUserDefaults] objectForKey:self.activitySyncKey];
    
    if (nil == savedStamp) {
        NSDate *longAgo = [NSDate dateWithTimeIntervalSince1970:0];
        return [self timestampForDate:longAgo];
    }
    
    return savedStamp;
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
        
        [self.syncQueue enqueueUpdateActivity:cmhActivity];
    }];
}

- (void)setEndDate:(NSDateComponents *)endDate
       forActivity:(OCKCarePlanActivity *)activity
        completion:(void (^)(BOOL, OCKCarePlanActivity * _Nullable, NSError * _Nullable))completion
{
    [super setEndDate:endDate forActivity:activity completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
        
        completion(success, activity, error);
        
        if (!success || nil == activity) {
            return;
        }
        
        CMHCareActivity *cmhActivity = [[CMHCareActivity alloc] initWithActivity:activity andUserId:self.cmhIdentifier];
        
        [self.syncQueue enqueueUpdateActivity:cmhActivity];
    }];
}

- (void)removeActivity:(OCKCarePlanActivity *)activity
            completion:(void (^)(BOOL, NSError * _Nullable))completion
{
    [super removeActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
        
        completion(success, error);
        
        if (!success || nil == activity) {
            return;
        }
        
        CMHCareActivity *cmhActivity = [[CMHCareActivity alloc] initWithActivity:activity andUserId:self.cmhIdentifier];
        cmhActivity.isDeleted = YES;
        
        [self.syncQueue enqueueUpdateActivity:cmhActivity];
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
        
        CMHCareEvent *cmhEvent = [[CMHCareEvent alloc] initWithEvent:event andUserId:self.cmhIdentifier];
        
        [self.syncQueue enqueueUpdateEvent:cmhEvent];
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

+ (nullable OCKCarePlanActivity *)activityWithIdentifier:(nonnull NSString *)identifier from:(nonnull NSArray<OCKCarePlanActivity *>*)activities
{
    for (OCKCarePlanActivity *activity in activities) {
        if ([activity.identifier isEqualToString:identifier]) {
            return activity;
        }
    }
    
    return nil;
}

+ (nonnull NSURL *)persistenceDirectoryNamed:(nonnull NSString *)name
{
    NSURL *appDirURL = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *namedDirURL = [appDirURL URLByAppendingPathComponent:name isDirectory:YES];
    
    NSAssert(nil != namedDirURL, @"Failed to create store directory URL: %@", namedDirURL);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[namedDirURL path] isDirectory:nil]) {
        NSError *dirError = nil;
        [[NSFileManager defaultManager] createDirectoryAtURL:namedDirURL withIntermediateDirectories:YES attributes:nil error:&dirError];
        NSAssert(nil == dirError, @"Error creating store directory: %@", dirError.localizedDescription);
    }
    
    return namedDirURL;
}

- (NSString *)timestampForDate:(NSDate *)date
{
    return [self.cmTimestampFormatter stringFromDate:date];
}

- (void)saveEventLastSyncTime:(NSDate *)date
{
    NSAssert(nil != date, @"Must provide NSDate to %@", __PRETTY_FUNCTION__);
    
    NSString *stamp = [self timestampForDate:date];
    [[NSUserDefaults standardUserDefaults] setObject:stamp forKey:self.eventSyncKey];
}

- (void)saveActivityLastSyncTime:(NSDate *)date
{
    NSAssert(nil != date, @"Must provide NSDate to %@", __PRETTY_FUNCTION__);
    
    NSString *stamp = [self timestampForDate:date];
    [[NSUserDefaults standardUserDefaults] setObject:stamp forKey:self.activitySyncKey];
}

- (void)syncRemoteEventsWithCompletion:(CMHRemoteSyncCompletion)block;
{
    CMStoreOptions *noLimitSharedOption = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:-1]];
    noLimitSharedOption.shared = YES;
    
    NSString *query = [NSString stringWithFormat:@"[%@ = \"%@\", %@ = \"%@\", %@ >= \"%@\"]", CMInternalClassStorageKey, [CMHCareEvent class], CMHOwningUserKey, self.cmhIdentifier, CMInternalUpdatedKey, self.eventLastSyncStamp];
    NSDate *syncStartTime = [NSDate new];
    
    [[CMStore defaultStore] searchUserObjects:query additionalOptions:noLimitSharedOption callback:^(CMObjectFetchResponse *response) {
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
                    // TODO: Ask Umer, shouldn't the domain and codes be in the public API
                    if ([updateStoreError.domain isEqualToString:@"OCKErrorDomain"] && updateStoreError.code == 1) {
                        NSLog(@"[CMHealth] Skipping update to event which is not in local store, and is assumed to be part of a deleted activity %@", wrappedEvent.ckEvent);
                    } else {
                        NSLog(@"[CMHEALTH] Error updating event in store: %@ (%@)`", wrappedEvent.ckEvent, updateStoreError);
                        [updateErrors addObject:updateStoreError];
                    }
                    
                    dispatch_group_leave(self.updateGroup);
                    self.eventBeingUpdated = nil;
                    continue;
                }
                
                dispatch_group_wait(self.updateGroup, DISPATCH_TIME_FOREVER);
                
                self.eventBeingUpdated = nil;
                
                NSLog(@"[CMHEALTH] Successfully updated event in store: %@", updatedEvent);
            }
            
            BOOL success = updateErrors.count < 1;
            if (success) {
                [self saveEventLastSyncTime:syncStartTime];
            }
            
            if (nil == block) {
                return;
            }
            
            block(success, [updateErrors copy]);
        });
    }];
}

- (void)syncRemoteActivitiesWithCompletion:(nullable CMHRemoteSyncCompletion)block;
{
    CMStoreOptions *noLimitSharedOption = [[CMStoreOptions alloc] initWithPagingDescriptor:[[CMPagingDescriptor alloc] initWithLimit:-1]];
    noLimitSharedOption.shared = YES;
    
    NSString *query = [NSString stringWithFormat:@"[%@ = \"%@\", %@ = \"%@\", %@ >= \"%@\"]", CMInternalClassStorageKey, [CMHCareActivity class], CMHOwningUserKey, self.cmhIdentifier, CMInternalUpdatedKey, self.activityLastSyncStamp];
    NSDate *syncStartTime = [NSDate new];
    
    [[CMStore defaultStore] searchUserObjects:query additionalOptions:noLimitSharedOption callback:^(CMObjectFetchResponse *response) {
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
                
                if (wrappedActivity.isDeleted) {
                    if (nil == storeActivity) {
                        NSLog(@"[CMHealth] Skipping fetched activity that is deleted and is not in store: %@", wrappedActivity.ckActivity);
                        continue;
                    }
                    
                    __block BOOL deleteSuccess = NO;
                    __block NSError *deleteError = nil;
                    
                    dispatch_group_enter(self.updateGroup);
                    self.isUpdatingActivity = YES;
                    
                    cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                        [super removeActivity:storeActivity completion:^(BOOL success, NSError * _Nullable error) {
                            deleteSuccess = success;
                            deleteError = error;
                            done();
                        }];
                    });
                    
                    if (!deleteSuccess) {
                        if (nil != deleteError) {
                            [updateErrors addObject:deleteError];
                        }
                        
                        NSLog(@"[CMHealth] Error removing deleted activity %@ from local store: %@", wrappedActivity.ckActivity, deleteError);
                        dispatch_group_leave(self.updateGroup);
                        self.isUpdatingActivity = NO;
                        continue;
                    }
                    
                    dispatch_group_wait(self.updateGroup, DISPATCH_TIME_FOREVER);
                    
                    self.isUpdatingActivity = NO;
                    NSLog(@"[CMHealth] Fetched deleted activity and removed it from local store: %@", storeActivity);
                    
                } else if (nil == storeActivity) {
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
                    __block updateStoreSuccess = NO;
                    __block NSError *updateStoreError = nil;
                    
                    dispatch_group_enter(self.updateGroup);
                    self.isUpdatingActivity = YES;
                    
                    cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
                       [super setEndDate:wrappedActivity.ckActivity.schedule.endDate forActivity:storeActivity completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
                           updateStoreSuccess = success;
                           updateStoreError = error;
                           done();
                       }];
                    });
                    
                    if (!updateStoreSuccess) {
                        if (nil != updateStoreError) {
                            [updateErrors addObject:updateStoreError];
                        }
                        
                        NSLog(@"[CMHEALTH] Error updating end date for fetched activity %@ to store: %@", wrappedActivity.ckActivity, updateStoreError.localizedDescription);
                        dispatch_group_leave(self.updateGroup);
                        self.isUpdatingActivity = NO;
                        continue;
                    }
                    
                    dispatch_group_wait(self.updateGroup, DISPATCH_TIME_FOREVER);
                    
                    self.isUpdatingActivity = NO;
                    NSLog(@"[CMHEALTH] Fetched activity and updated schedule (end date): %@", wrappedActivity.ckActivity);
                }
            }
            
            BOOL success = updateErrors.count < 1;
            if (success) {
                [self saveActivityLastSyncTime:syncStartTime];
            }
            
            if (nil == block) {
                return;
            }
            
            block(success, [updateErrors copy]);
        });
    }];
}

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
