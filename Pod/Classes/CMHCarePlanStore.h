#import <CareKit/CareKit.h>
#import "CMHCareSyncBlocks.h"

typedef void(^CMHFetchPatientsCompletion)(BOOL success, NSArray<OCKPatient *> *_Nonnull patients, NSArray<NSError *> *_Nonnull errors);

/**
 *  The CMHealth compatible subclass of CareKit's OCKCarePlanStore. This class
 *  can be interacted with as a standard OCKCarePlanStore. Behind the
 *  scenes, this store will automatically push all additions and changes made to the
 *  data to the CloudMine Connected Health Cloud. The class also adds methods for
 *  fetching all remote data to the local device, allowing you to
 *  create CareKit apps that sync across devices and accounts.
 */
@interface CMHCarePlanStore : OCKCarePlanStore

/**
 *  Returns a store which persists it's data locally in the specified directory and
 *  pushes data to CloudMine for the currently logged in CMHUser. This method should
 *  only be called if a CMHUser is currently logged in.
 *
 *  @warning This method should only be called in the context of a patient
 *  CareKit app where patient is the currently logged in CMHUser
 *
 *  @param URL The directory for the store to save its database file
 */
+ (nonnull instancetype)storeWithPersistenceDirectoryURL:(nonnull NSURL *)URL;

/**
 *  Returns, via block callback, an array of all OCKPatient instances currently
 *  persisted in the CloudMine Connected Health Cloud for this app. This method
 *  assumes the currently logged in user is an "admin" user with proper ACL permissions
 *  to fetch all patient data.
 *
 *  Subsequent calls to this method will produce a new array of patients intances, but
 *  will intelligently sync only that patient data which has changed remotely since the last time
 *  this method was called. Thus, it is safe to call this method as a way to "refresh" the
 *  current list of patients and their data.
 *
 *  @warning This method should only be called when logged in as an appropriately
 *  credentialed administrator account, in the context of a Care Provider CareKit app
 *
 *  @param block Executes when the fetch request completes successfully or fails with an error
 */
+ (void)fetchAllPatientsWithCompletion:(nonnull CMHFetchPatientsCompletion)block;

/**
 *  Fetches, and persists, all remote CareKit data associated with this user that
 *  has been created or updated since the last time it was called. Returns, via block
 *  callback, success/failure state. In the case of failure, an array of encountered errors
 *  is also returned. In the case of failure, a delayed-retry is highly advised.
 *  
 *  If the user has recently changed data locally, the call to fetch remote data will not
 *  execute until all pending updates have pushed. Multiple calls to this method will occur
 *  serially and in the order in which they were made.
 *
 *  @warning This method should only be called when logged in as an appropriately
 *  credentialed administrator account, in the context of a Care Provider CareKit app.
 *  To refresh data in a CareProvider app, see `+fetchAllPatientsWithCompletion:`
 *
 *  @param block Executes when the synchronization request completes successfully or 
 *         fails with an error
 */
- (void)syncFromRemoteWithCompletion:(nullable CMHRemoteSyncCompletion)block;

/**
 *  Synchronously removes all local state associated with this CMHCarePlanStore. This
 *  includes all persisted activities and events, as well as internal tokens used for
 *  data synchronization. This method has no effect on the data stored remotely but is
 *  specifically intended for clearing local data after the user logs out. Calling this
 *  method for any reason other than clearing local data after a logout is not advised.
 *
 *  @warning This method blocks the current thread and may take several seconds to
 *  execute in cases with a large amount of local data. Calling this method on a
 *  background thread is advised.
 */
- (void)clearLocalStore;

- (_Null_unspecified instancetype)initWithPersistenceDirectoryURL:(NSURL *_Null_unspecified)URL NS_UNAVAILABLE;

- (_Null_unspecified instancetype)initWithPersistenceDirectoryURL:(NSURL *_Null_unspecified)URL
                                     identifier:(NSString *_Null_unspecified)identifier
                                                          patient:(OCKPatient *_Null_unspecified)patient NS_UNAVAILABLE;

@end
