#import "CMHCarePlanStore_internal.h"
#import "OCKCarePlanEvent+CMHealth.h"
#import "OCKCarePlanActivity+CMHealth.h"
#import "CMHInternalUser.h"
#import "CMHCareActivity.h"
#import "CMHCareEvent.h"
#import "CMHErrorUtilities.h"
#import "CMHDisptachUtils.h"
#import "CMHCareObjectSaver.h"
#import "CMHConfiguration.h"
#import "CMHInternalProfile.h"
#import "CMHCareSyncQueue.h"
#import "CMHCarePlanStoreVendor.h"
#import "CMHSyncStamper.h"
#import "CMHAutoPager.h"
#import "CMHUserData_internal.h"
#import "OCKPatient+CMHealth.h"

@interface CMHCarePlanStore ()<OCKCarePlanStoreDelegate>

@property (nonatomic, weak) id<OCKCarePlanStoreDelegate> passDelegate;
@property (nonatomic, nonnull) NSString *cmhIdentifier;

@property (nonatomic, nonnull) dispatch_group_t updateGroup;
@property (nonatomic, nullable) CMHCareEvent *eventBeingUpdated;
@property (nonatomic) BOOL isUpdatingActivity; // Can only do a flag because delegate callback does not include activity info; could drop 'real' activity updates

@property (nonatomic, nonnull) CMHSyncStamper *stamper;
@property (nonatomic, nonnull) CMHCareSyncQueue *syncQueue;

@end

@implementation CMHCarePlanStore

#pragma mark Initialization

- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)URL
{
    NSAssert(false, @"-initWithPerasistenceDirectoryURL: is unavailable for CMHCarePlanStore, use +cloudMineStoreWithPersistenceDirectoryURL:");
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
    _stamper = [[CMHSyncStamper alloc] initWithCMHIdentifier:_cmhIdentifier];
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
    [self.syncQueue enqueueFetchForStore:self completion:block];
}

- (void)clearLocalStore
{
    NSArray *errors = [self clearLocalStoreDataSynchronously];
    [self.stamper forgetSyncTime];
    
    if (errors.count > 0) {
        NSLog(@"[CMHEALTH] There were %li errors clearing the local store: %@", (long)errors.count, errors);
    } else {
        NSLog(@"[CMHEALTH] Successfully flushed the local store");
    }
}

+ (void)fetchAllPatientsWithCompletion:(CMHFetchPatientsCompletion)block
{
    NSAssert(nil != block, @"Cannot call %s without completion block parameter", __PRETTY_FUNCTION__);
    
    dispatch_queue_t highQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(highQueue, ^{
        __block NSArray *allUsers = nil;
        __block NSArray *userErrors = nil;
        
        cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
            [CMHAutoPager fetchAllUsersWithCompletion:^(NSArray<CMUser *> *users, NSArray<NSError *> *errors) {
                allUsers = users;
                userErrors = errors;
                done();
            }];
        });
        
        if (nil != userErrors && userErrors.count > 0) {
            block(NO, @[], userErrors);
            return;
        }
        
        __block NSArray *allProfiles = @[];
        __block NSError *profilesError = nil;
        
        cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
            [CMHAutoPager fetchAllUserProfilesWithCompletion:^(NSArray<CMHInternalProfile *> *profiles, NSError *error) {
                allProfiles = profiles;
                profilesError = error;
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
            
            NSString *patientName = user.email;
            NSString *patientDetail = nil;
            CMHInternalProfile *profile = [CMHCarePlanStore profileForUser:(CMHInternalUser *)user from:allProfiles];
            CMHUserData *userData = [[CMHUserData alloc] initWithInternalProfile:profile userId:user.objectId];
            
            if (nil == profile || profile.isAdmin || nil == userData) {
                continue;
            }

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
            
            NSDictionary *patientInfo = nil;
            
            if (nil != profile.photoId) {
                patientInfo =  @{ CMHPatientUserInfoUserDataKey: userData,
                                  CMHPatientUserInfoPhotoIdKey: profile.photoId, };
            } else {
                patientInfo = @{ CMHPatientUserInfoUserDataKey: userData, };
            }
            
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
            
            OCKPatient *patient = [[OCKPatient alloc] initWithIdentifier:user.objectId
                                                           carePlanStore:patientStore
                                                                    name:patientName
                                                              detailInfo:patientDetail
                                                        careTeamContacts:nil
                                                               tintColor:nil
                                                                monogram:nil
                                                                   image:nil
                                                              categories:nil
                                                                userInfo:patientInfo];
            [mutablePatients addObject:patient];
        }
        
        block(YES, [mutablePatients copy], @[]);
    });
}

+ (nullable CMHInternalProfile *)profileForUser:(nonnull CMHInternalUser *)user from:(nonnull NSArray<CMHInternalProfile *> *)profiles
{
    NSAssert(nil != user && nil != profiles, @"%s called without a user and profiles array", __PRETTY_FUNCTION__);
    
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

#pragma mark Protected API

- (void)runFetchWithCompletion:(nullable CMHRemoteSyncCompletion)block
{
    NSDate *syncStartTime = [NSDate new];
    
    [CMHAutoPager fetchObjectsWithOwningUser:self.cmhIdentifier updatedAfter:self.stamper.lastSyncStamp withCompletion:^(NSArray<CMObject *> *allObjects, NSError *fetchError) {
        if (nil != fetchError) {
            if (nil != block) {
                block(NO, @[fetchError]);
            }
            return;
        }
        
        NSArray<CMHCareActivity *> *fetchedActivities = [self.class objectsOfClass:[CMHCareActivity class] from:allObjects];
        NSArray<CMHCareEvent *> *fetchedEvents = [self.class objectsOfClass:[CMHCareEvent class] from:allObjects];
        
        [self insertActivities:fetchedActivities completion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
            if (!success) {
                NSLog(@"[CMHEALTH] Error syncing activities: %@", errors);
                
                if (nil != block) {
                    block(NO, errors);
                }
                return;
            }
            
            [self insertEvents:fetchedEvents completion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
                if (!success) {
                    NSLog(@"[CMHEALTH] Error syncing events: %@", errors);
                    
                    if (nil != block) {
                        block(NO, errors);
                    }
                    return;
                }
                
                NSLog(@"[CMHEALTH] Successful sync of events");
                
                [self.stamper saveLastSyncTime:syncStartTime];
                
                if (nil != block) {
                    block(YES, @[]);
                }
            }];
        }];
    }];
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

#pragma mark Overrides

- (void)addActivity:(OCKCarePlanActivity *)activity completion:(void (^)(BOOL, NSError * _Nullable))completion
{
    [self.syncQueue incrementPreQueueCount];
    
    __weak typeof(self) weakSelf = self;
    
    [super addActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
        completion(success, error);
        
        if (!success) {
            [weakSelf.syncQueue decrementPreQueueCount];
            return;
        }
        
        CMHCareActivity *cmhActivity = [[CMHCareActivity alloc] initWithActivity:activity andUserId:weakSelf.cmhIdentifier];
        [weakSelf.syncQueue enqueueUpdateActivity:cmhActivity];
    }];
}

- (void)setEndDate:(NSDateComponents *)endDate
       forActivity:(OCKCarePlanActivity *)activity
        completion:(void (^)(BOOL, OCKCarePlanActivity * _Nullable, NSError * _Nullable))completion
{
    [self.syncQueue incrementPreQueueCount];
    
    __weak typeof(self) weakSelf = self;
    
    [super setEndDate:endDate forActivity:activity completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
        
        completion(success, activity, error);
        
        if (!success || nil == activity) {
            [weakSelf.syncQueue decrementPreQueueCount];
            return;
        }
        
        CMHCareActivity *cmhActivity = [[CMHCareActivity alloc] initWithActivity:activity andUserId:weakSelf.cmhIdentifier];
        [weakSelf.syncQueue enqueueUpdateActivity:cmhActivity];
    }];
}

- (void)removeActivity:(OCKCarePlanActivity *)activity
            completion:(void (^)(BOOL, NSError * _Nullable))completion
{
    [self.syncQueue incrementPreQueueCount]; // Archive
    [self.syncQueue incrementPreQueueCount]; // Delete
    
    __weak typeof(self) weakSelf = self;
    
    [super removeActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
        
        completion(success, error);
        
        if (!success || nil == activity) {
            [weakSelf.syncQueue decrementPreQueueCount];
            [weakSelf.syncQueue decrementPreQueueCount];
            return;
        }
        
        CMHCareActivity *cmhArchiveActivity = [[CMHCareActivity alloc] initWithActivity:activity userId:weakSelf.cmhIdentifier isDeleted:YES];
        [weakSelf.syncQueue enqueueUpdateActivity:cmhArchiveActivity];
        
        CMHCareActivity *cmhRemoveActivity = [[CMHCareActivity alloc] initWithActivity:activity userId:weakSelf.cmhIdentifier isDeleted:NO];
        [weakSelf.syncQueue enqueueDeleteActivity:cmhRemoveActivity];
    }];
}

- (void)updateEvent:(OCKCarePlanEvent *)event
         withResult:(OCKCarePlanEventResult *)result
              state:(OCKCarePlanEventState)state
         completion:(void (^)(BOOL, OCKCarePlanEvent * _Nullable, NSError * _Nullable))completion
{
    [self.syncQueue incrementPreQueueCount];
    
    __weak typeof(self) weakSelf = self;
    
    [super updateEvent:event withResult:result state:state completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
        completion(success, event, error);
        
        if (!success) {
            [weakSelf.syncQueue decrementPreQueueCount];
            return;
        }
        
        CMHCareEvent *cmhEvent = [[CMHCareEvent alloc] initWithEvent:event andUserId:weakSelf.cmhIdentifier];
        
        [weakSelf.syncQueue enqueueUpdateEvent:cmhEvent];
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

+ (nonnull NSArray*)objectsOfClass:(Class)klass from:(nonnull NSArray<CMObject *> *)allObjects
{
    NSMutableArray *mutableObjectsOfClass = [NSMutableArray new];
    
    for (CMObject *object in allObjects) {
        if ([object isKindOfClass:klass]) {
            [mutableObjectsOfClass addObject:object];
        }
    }
    
    return [mutableObjectsOfClass copy];
}

+ (nonnull NSArray<CMHCareActivity *> *)activitiesWhichAreDeleted:(BOOL)shouldReturnDeleted from:(nonnull NSArray<CMHCareActivity *> *)allActivities
{
    NSMutableArray<CMHCareActivity *> *mutableActivies = [NSMutableArray new];
    
    for (CMHCareActivity *activity in allActivities) {
        if (activity.isDeleted == shouldReturnDeleted) {
            [mutableActivies addObject:activity];
        }
    }
    
    return [mutableActivies copy];
}

- (void)insertEvents:(nonnull NSArray<CMHCareEvent *> *)wrappedEvents completion:(CMHRemoteSyncCompletion)block
{
    dispatch_queue_t updateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(updateQueue, ^{
        NSMutableArray<NSError *> *updateErrors = [NSMutableArray new];
        
        for (CMHCareEvent *wrappedEvent in wrappedEvents) {
            BOOL activityStoreSuccess = NO;
            NSError *activityStoreError = nil;
            OCKCarePlanActivity *storeActivity = [self serialActivityForIdentifier:wrappedEvent.ckEvent.activity.identifier success:&activityStoreSuccess error:&activityStoreError];
            
            if (nil == storeActivity || !activityStoreSuccess) {
                NSLog(@"[CMHealth] Skipping update to event whose activity is not in local store, and is assumed to be part of a deleted activity %@", wrappedEvent.ckEvent);
                continue;
            } else if (![wrappedEvent.ckEvent.activity isEqualExceptEndDate:storeActivity]) {
                NSLog(@"[CMHealth] Skipping update to event whose activity is different from the one now in the store- it must have been deleted & replaced %@", wrappedEvent.ckEvent);
                continue;
            }
            
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
                NSLog(@"[CMHEALTH] Error updating event in store: %@ (%@)`", wrappedEvent.ckEvent, updateStoreError);
                
                [updateErrors addObject:updateStoreError];
                
                dispatch_group_leave(self.updateGroup);
                self.eventBeingUpdated = nil;
                
                continue;
            }
            
            dispatch_group_wait(self.updateGroup, DISPATCH_TIME_FOREVER);
            
            self.eventBeingUpdated = nil;
            
            NSLog(@"[CMHEALTH] Successfully updated event in store: %@", updatedEvent);
        }
        
        BOOL success = updateErrors.count < 1;
        
        if (nil == block) {
            return;
        }
        
        block(success, [updateErrors copy]);
    });
}

- (void)insertActivities:(nonnull NSArray<CMHCareActivity *> *)wrappedActivities completion:(nullable CMHRemoteSyncCompletion)block
{
    dispatch_queue_t updateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(updateQueue, ^{
        NSMutableArray<NSError *> *updateErrors = [NSMutableArray new];
        
        NSArray<CMHCareActivity *> *deletedActivities = [self.class activitiesWhichAreDeleted:YES from:wrappedActivities];
        
        for (CMHCareActivity *wrappedActivity in deletedActivities) {
            NSAssert(wrappedActivity.isDeleted, @"Attempted to deleted an activity not marked as such; ID: %@",  wrappedActivity.objectId);
            
            BOOL storeSuccess = NO;
            NSError *storeError = nil;
            OCKCarePlanActivity *storeActivity = [self serialActivityForIdentifier:wrappedActivity.ckActivity.identifier success:&storeSuccess error:&storeError];
            
            if (!storeSuccess) {
                if (nil != storeError) {
                    [updateErrors addObject:storeError];
                }
                
                if (nil != block) {
                    block(NO, [updateErrors copy]);
                }
                
                return;
            }
            
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
        }
        
        NSArray<CMHCareActivity *> *currentActivities = [self.class activitiesWhichAreDeleted:NO from:wrappedActivities];
        
        for (CMHCareActivity *wrappedActivity in currentActivities) {
            NSAssert(!wrappedActivity.isDeleted, @"Attempted to insert an activity that is marked as deleted; ID: %@",  wrappedActivity.objectId);
            
            BOOL storeSuccess = NO;
            NSError *storeError = nil;
            OCKCarePlanActivity *storeActivity = [self serialActivityForIdentifier:wrappedActivity.ckActivity.identifier success:&storeSuccess error:&storeError];
            
            if (!storeSuccess) {
                if (nil != storeError) {
                    [updateErrors addObject:storeError];
                }
                
                if (nil != block) {
                    block(NO, [updateErrors copy]);
                }
                
                return;
            }

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
                __block BOOL updateStoreSuccess = NO;
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
        
        if (nil == block) {
            return;
        }
        
        block(success, [updateErrors copy]);
    });
}

- (nullable OCKCarePlanActivity *)serialActivityForIdentifier:(nonnull NSString *)identifier
                                                      success:(BOOL *)successPtr
                                                        error:(NSError * __autoreleasing *)errorPtr
{
    __block BOOL storeSuccess = NO;
    __block OCKCarePlanActivity *storeActivity = nil;
    __block NSError *storeError = nil;
    
    cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
        [super activityForIdentifier:identifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
            storeSuccess = success;
            storeActivity = activity;
            storeError = error;
            done();
        }];
    });
    
    *successPtr = storeSuccess;
    *errorPtr = storeError;
    
    return storeActivity;
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
