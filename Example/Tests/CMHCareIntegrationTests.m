#import <CMHealth/CMHealth.h>
#import <CloudMine/CMUser.h>
#import <CloudMine/CMStore.h>
#import "CMHTest-Secrets.h"
#import "CMHCareTestFactory.h"
#import "CMHTestCleaner.h"
#import <CMHealth/CMHCareActivity.h>
#import <CMHealth/CMHCareEvent.h>
#import <CMHealth/CMHInternalUser.h>
#import <CMHealth/CMHCareObjectSaver.h>
#import <CMHealth/CMHCarePlanStoreVendor.h>
#import <CMHealth/CareKit+CMHealth.h>

@interface CMHCareIntegrationTestUtils : NSObject
+ (NSURL *)persistenceDirectory;
@end

@implementation CMHCareIntegrationTestUtils

+ (NSURL *)persistenceDirectory
{
    NSURL *appDirURL = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    
    NSAssert(nil != appDirURL, @"[CMHealth] Failed to create store director URL");
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[appDirURL path] isDirectory:nil]) {
        NSError *dirError = nil;
        [[NSFileManager defaultManager] createDirectoryAtURL:appDirURL withIntermediateDirectories:YES attributes:nil error:&dirError];
        NSAssert(nil == dirError, @"[CMHealth] Error creating store directory: %@", dirError.localizedDescription);
    }
    
    return appDirURL;
}

@end

static NSString *const CareTestPassword = @"test-Password2!!";

SpecBegin(CMHCareIntegration)

describe(@"CMHCareIntegration", ^{
    
    beforeAll(^{
        NSString *assertionError = @"You haven't set valid credentials in CMHTest-Secrets.h";
        NSAssert(CMHTestsAppId.length > 0, assertionError);
        NSAssert(![CMHTestsAppId isEqualToString:@"REPLACE_WITH_AN_APP_ID_TO_USE_FOR_TESTING"], assertionError);
        NSAssert(CMHTestsAPIKey.length > 0, assertionError);
        NSAssert(![CMHTestsAPIKey isEqualToString:@"REPLACE_WITH_API_KEY"], assertionError);
        NSAssert(CMHTestsSharedSnippetName.length > 0, assertionError);
        NSAssert(![CMHTestsSharedSnippetName isEqualToString:@"REPLACE_WITH_A_SNIPPET_FOR_SHARING_SAVED_CAREKIT_DATA_TO_USE_FOR_TESTING"], assertionError);
        NSAssert(CMHTestsAsyncTimeout >= 1.0, @"An async timeout of less than 1 second is not advised; tests will run as fast as your connection allows regardless of the timeout value; lowering the value will not speed up test time and can lead to false failures.");
        
        [CMHealth setAppIdentifier:CMHTestsAppId appSecret:CMHTestsAPIKey sharedUpdateSnippetName:CMHTestsSharedSnippetName];
        setAsyncSpecTimeout(CMHTestsAsyncTimeout);

        waitUntil(^(DoneCallback done) {
            if([CMHUser currentUser].isLoggedIn) {
                CMHCarePlanStore *store = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
                [[CMHUser currentUser] logoutWithCompletion:^(NSError *error){
                    [store clearLocalStore];
                    done();
                }];
            } else {
                done();
            }
        });
        
        NSAssert(![CMHUser currentUser].isLoggedIn, @"Failed to log user out before beginning test");
    });
    
    it(@"should create and login a user with email and password", ^{
        __block NSError *signupError = nil;
        
        NSString *unixTime = [NSNumber numberWithInt:(int)[NSDate new].timeIntervalSince1970].stringValue;
        NSString *emailAddress = [NSString stringWithFormat:@"cmcare+%@@cloudmineinc.com", unixTime];
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] signUpWithEmail:emailAddress password:CareTestPassword andCompletion:^(NSError * _Nullable error) {
                signupError = error;
                done();
            }];
        });
        
        expect(signupError).to.beNil();
        expect([CMHUser currentUser].isLoggedIn).to.beTruthy();
        expect([CMHUser currentUser].userData.email).to.equal(emailAddress);
        expect([CMHUser currentUser].userData.userId).notTo.beNil();
        expect([CMHUser currentUser].userData.isAdmin).to.beFalsy();
    });
    
    it(@"should let us update the user's profile data", ^{
        __block CMHUserData *updateUserData = nil;
        __block NSError *updateError = nil;
        
        CMHMutableUserData *mutableUserData = [[CMHUser currentUser].userData mutableCopy];
        mutableUserData.gender = CMHCareTestFactory.genderString;
        mutableUserData.dateOfBirth = CMHCareTestFactory.dateOfBirth;
        mutableUserData.userInfo = CMHCareTestFactory.userDataUserInfo;
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] updateUserData:mutableUserData withCompletion:^(CMHUserData * _Nullable userData, NSError * _Nullable error) {
                updateUserData = userData;
                updateError = error;
                done();
            }];
        });
        
        expect(updateError).to.beNil();
        expect(updateUserData == [CMHUser currentUser].userData).to.beTruthy();
        expect(updateUserData.isAdmin).to.equal(NO);
        expect(updateUserData.gender).to.equal(CMHCareTestFactory.genderString);
        expect(updateUserData.dateOfBirth).to.equal(CMHCareTestFactory.dateOfBirth);
        expect(updateUserData.userInfo).to.equal(CMHCareTestFactory.userDataUserInfo);
    });
    
    it(@"should upload a user's profile photo", ^{
        UIImage *image = [UIImage imageNamed:@"Test-Signature-Image.png"];
        
        expect(image).notTo.beNil();
        
        __block BOOL uploadSuccess = NO;
        __block NSError *uploadError = nil;
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] uploadProfileImage:image withCompletion:^(BOOL success, NSError *error) {
                uploadSuccess = success;
                uploadError = error;
                done();
            }];
        });
        
        expect(uploadSuccess).to.beTruthy();
        expect(uploadError).to.beNil();
    });
    
    it(@"should create a store for the current user and always return the same instance for that store", ^{
        CMHCarePlanStore *storeOne = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        CMHCarePlanStore *storeTwo = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        
        expect(storeOne == storeTwo).to.beTruthy();
    });
    
    it(@"should push and pull activities to/from the store/server", ^{
        CMHCarePlanStore *store = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        
        __block BOOL addSuccess = NO;
        __block NSError * addError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store addActivity:CMHCareTestFactory.interventionActivity completion:^(BOOL success, NSError *error) {
                addSuccess = success;
                addError = error;
                done();
            }];
        });
        
        expect(addSuccess).to.beTruthy();
        expect(addError).to.beNil();
        
        // Simulate adding of an activity remotely by saving it directly using internal
        // API's, rather than going through the store
        CMHCareActivity *activityWrapper = [[CMHCareActivity alloc] initWithActivity:CMHCareTestFactory.assessmentActivity andUserId:[CMHInternalUser currentUser].objectId];
        
        __block NSString *saveStatus = nil;
        __block NSError *saveError = nil;
        
        waitUntil(^(DoneCallback done) {
            [CMHCareObjectSaver saveCMHCareObject:activityWrapper withCompletion:^(NSString * _Nullable status, NSError * _Nullable error) {
                saveStatus = status;
                saveError = error;
                done();
            }];
        });
        
        expect(saveStatus).to.equal(@"created");
        expect(saveError).to.beNil();
        
        __block BOOL syncSuccess = NO;
        __block NSArray *syncErrors = nil;
        
        waitUntil(^(DoneCallback done) {
            [store syncFromRemoteWithCompletion:^(BOOL success, NSArray<NSError *> *errors) {
                syncSuccess = success;
                syncErrors = errors;
                done();
            }];
        });
        
        expect(syncSuccess).to.beTruthy();
        expect(0 == syncErrors.count).to.beTruthy();
        
        __block BOOL interventionSuccess = NO;
        __block OCKCarePlanActivity *interventionActivity = nil;
        __block NSError *interventionError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store activityForIdentifier:CMHCareTestFactory.interventionActivity.identifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
                interventionSuccess = success;
                interventionActivity = activity;
                interventionError = error;
                done();
            }];
        });
        
        expect(interventionSuccess).to.beTruthy();
        expect(interventionActivity).notTo.beNil();
        expect(interventionActivity == CMHCareTestFactory.interventionActivity).to.beFalsy();
        expect(interventionActivity).to.equal(CMHCareTestFactory.interventionActivity);
        expect(interventionError).to.beNil();
        
        __block BOOL assessmentSucces = NO;
        __block OCKCarePlanActivity *assessmentActivity = nil;
        __block NSError *asssessmentError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store activityForIdentifier:CMHCareTestFactory.assessmentActivity.identifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
                assessmentSucces = success;
                assessmentActivity = activity;
                asssessmentError = error;
                done();
            }];
        });
        
        expect(assessmentSucces).to.beTruthy();
        expect(assessmentActivity).notTo.beNil();
        expect(assessmentActivity == CMHCareTestFactory.assessmentActivity).to.beFalsy();
        expect(assessmentActivity).to.equal(CMHCareTestFactory.assessmentActivity);
        expect(asssessmentError).to.beNil();
    });
    
    it(@"should push and pull events to and from the backend", ^{
        CMHCarePlanStore *store = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        
        // Ensure Intervention Event is in initial State
        
        __block OCKCarePlanEvent *interventionEvent = nil;
        __block NSError *interventionEventError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store eventsForActivity:CMHCareTestFactory.interventionActivity date:CMHCareTestFactory.todayComponents completion:^(NSArray<OCKCarePlanEvent *> *events, NSError *error) {
                interventionEvent = events.firstObject;
                interventionEventError = error;
                done();
            }];
        });
        
        expect(interventionEventError).to.beNil();
        expect(interventionEvent).notTo.beNil();
        expect(OCKCarePlanEventStateInitial == interventionEvent.state).to.beTruthy();
        
        // Update Intervention Event through the store
        
        __block BOOL interventionUpdateSuccess = NO;
        __block OCKCarePlanEvent *interventionUpdateEvent = nil;
        __block NSError *interventionUpdateError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store updateEvent:interventionEvent withResult:nil state:OCKCarePlanEventStateCompleted completion:^(BOOL success, OCKCarePlanEvent *event, NSError *error){
                interventionUpdateSuccess = success;
                interventionUpdateEvent = event;
                interventionUpdateError = error;
                done();
            }];
        });
        
        expect(interventionUpdateSuccess).to.beTruthy();
        expect(interventionUpdateError).to.beNil();
        expect(interventionUpdateEvent).notTo.beNil();
        expect(OCKCarePlanEventStateCompleted == interventionUpdateEvent.state).to.beTruthy();
        
        // Ensure Assessment Event is in intial state
        
        __block OCKCarePlanEvent *assessmentEvent = nil;
        __block NSError *assessmentEventError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store eventsForActivity:CMHCareTestFactory.assessmentActivity date:CMHCareTestFactory.todayComponents completion:^(NSArray<OCKCarePlanEvent *> *events, NSError *error){
                assessmentEvent = events.firstObject;
                assessmentEventError = error;
                done();
            }];
        });
        
        expect(assessmentEventError).to.beNil();
        expect(assessmentEvent).notTo.beNil();
        expect(OCKCarePlanEventStateInitial == assessmentEvent.state).to.beTruthy();
        expect(assessmentEvent.result).to.beNil();
        
        // Manually update the Assessment Event record on the backend
        
        NSAssert([assessmentEvent respondsToSelector:@selector(setResult:)] && [assessmentEvent respondsToSelector:@selector(setState:)], @"Internal API of OCKCarePlanEvent used for testing has changed");
        
        [assessmentEvent performSelector:@selector(setResult:) withObject:CMHCareTestFactory.assessmentEventResult];
        
        NSMethodSignature *signature = [[assessmentEvent class] instanceMethodSignatureForSelector:@selector(setState:)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = assessmentEvent;
        invocation.selector = @selector(setState:);
        OCKCarePlanEventState completeState = OCKCarePlanEventStateCompleted;
        [invocation setArgument:&completeState atIndex:2];
        [invocation invoke];
        
        NSAssert(nil != assessmentEvent.result && OCKCarePlanEventStateCompleted == assessmentEvent.state, @"Failed to set assessment event result using internal API");
        
        CMHCareEvent *careEvent = [[CMHCareEvent alloc] initWithEvent:assessmentEvent andUserId:[CMHInternalUser currentUser].objectId];
        
        __block NSString *saveStatus = nil;
        __block NSError *saveError = nil;
        
        waitUntil(^(DoneCallback done) {
            [CMHCareObjectSaver saveCMHCareObject:careEvent withCompletion:^(NSString *status, NSError *error) {
                saveStatus = status;
                saveError = error;
                done();
            }];
        });
        
        expect(saveError).to.beNil();
        expect(saveStatus).to.equal(@"created");
        
        // Sync remote data into the local store
        
        __block BOOL syncSuccess = NO;
        __block NSArray *syncErrors = nil;
        
        waitUntil(^(DoneCallback done) {
            [store syncFromRemoteWithCompletion:^(BOOL success, NSArray<NSError *> *errors) {
                syncSuccess = success;
                syncErrors = errors;
                done();
            }];
        });
        
        expect(syncSuccess).to.beTruthy();
        expect(0 == syncErrors.count).to.beTruthy();
        
        // Ensure Intervention Event is in expected state
        
        interventionEvent = nil;
        interventionEventError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store eventsForActivity:CMHCareTestFactory.interventionActivity date:CMHCareTestFactory.todayComponents completion:^(NSArray<OCKCarePlanEvent *> *events, NSError *error) {
                interventionEvent = events.firstObject;
                interventionEventError = error;
                done();
            }];
        });
        
        expect(interventionEventError).to.beNil();
        expect(interventionEvent).notTo.beNil();
        expect(OCKCarePlanEventStateCompleted == interventionEvent.state).to.beTruthy();
        
        // Ensure Assessment event is in expected state
        
       assessmentEvent = nil;
       assessmentEventError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store eventsForActivity:CMHCareTestFactory.assessmentActivity date:CMHCareTestFactory.todayComponents completion:^(NSArray<OCKCarePlanEvent *> *events, NSError *error){
                assessmentEvent = events.firstObject;
                assessmentEventError = error;
                done();
            }];
        });
        
        expect(assessmentEventError).to.beNil();
        expect(assessmentEvent).notTo.beNil();
        expect(OCKCarePlanEventStateCompleted == assessmentEvent.state).to.beTruthy();
        expect(assessmentEvent.result).notTo.beNil();
        expect(assessmentEvent.result.valueString).to.equal(CMHCareTestFactory.assessmentEventResult.valueString);
        expect(assessmentEvent.result.unitString).to.equal(CMHCareTestFactory.assessmentEventResult.unitString);
        //expect(assessmentEvent.result.creationDate.timeIntervalSince1970 == CMHCareTestFactory.assessmentEventResult.creationDate.timeIntervalSince1970).to.beTruthy();
        expect(assessmentEvent.result.userInfo).to.equal(CMHCareTestFactory.assessmentEventResult.userInfo);
    });
    
    it(@"should maintain data integrity after logout, login and resync", ^{
        CMHCarePlanStore *store = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        NSString *email = [CMHUser currentUser].userData.email;
        
        expect(email).notTo.beNil();
        
        __block NSError *logoutError = nil;
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] logoutWithCompletion:^(NSError * error) {
                logoutError = error;
                [store clearLocalStore];
                done();
            }];
        });
        
        expect(logoutError).to.beNil();
        expect([CMHUser currentUser].isLoggedIn).to.beFalsy();
        
        __block BOOL clearedActivitiesSuccess = NO;
        __block NSArray *clearedActivities = nil;
        __block NSError *clearedActivitiesError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError  *error) {
                clearedActivitiesSuccess = success;
                clearedActivities = activities;
                error = clearedActivitiesError;
                done();
            }];
        });
        
        expect(clearedActivitiesSuccess).to.beTruthy();
        expect(clearedActivitiesError).to.beNil();
        expect(0 == clearedActivities.count).to.beTruthy();
        
        __block NSError *loginError = nil;
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] loginWithEmail:email password:CareTestPassword andCompletion:^(NSError * error) {
                loginError = error;
                done();
            }];
        });
        
        expect(loginError).to.beNil();
        expect([CMHUser currentUser].isLoggedIn).to.beTruthy();
        
        __block BOOL syncSuccess = NO;
        __block NSArray *syncErrors = nil;
        
        waitUntil(^(DoneCallback done) {
            [store syncFromRemoteWithCompletion:^(BOOL success, NSArray<NSError *> *errors) {
                syncSuccess = success;
                syncErrors = errors;
                done();
            }];
        });
        
        expect(syncSuccess).to.beTruthy();
        expect(0 == syncErrors.count).to.beTruthy();
        
        __block BOOL interventionSuccess = NO;
        __block OCKCarePlanActivity *interventionActivity = nil;
        __block NSError *interventionError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store activityForIdentifier:CMHCareTestFactory.interventionActivity.identifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
                interventionSuccess = success;
                interventionActivity = activity;
                interventionError = error;
                done();
            }];
        });
        
        expect(interventionSuccess).to.beTruthy();
        expect(interventionActivity).notTo.beNil();
        expect(interventionActivity == CMHCareTestFactory.interventionActivity).to.beFalsy();
        expect(interventionActivity).to.equal(CMHCareTestFactory.interventionActivity);
        expect(interventionError).to.beNil();
        
        __block BOOL assessmentSuccess = NO;
        __block OCKCarePlanActivity *assessmentActivity = nil;
        __block NSError *asssessmentError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store activityForIdentifier:CMHCareTestFactory.assessmentActivity.identifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
                assessmentSuccess = success;
                assessmentActivity = activity;
                asssessmentError = error;
                done();
            }];
        });
        
        expect(assessmentSuccess).to.beTruthy();
        expect(assessmentActivity).notTo.beNil();
        expect(assessmentActivity).to.equal(CMHCareTestFactory.assessmentActivity);
        expect(asssessmentError).to.beNil();
        
        __block OCKCarePlanEvent *interventionEvent = nil;
        __block NSError *interventionEventError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store eventsForActivity:CMHCareTestFactory.interventionActivity date:CMHCareTestFactory.todayComponents completion:^(NSArray<OCKCarePlanEvent *> *events, NSError *error) {
                interventionEvent = events.firstObject;
                interventionEventError = error;
                done();
            }];
        });
        
        expect(interventionEventError).to.beNil();
        expect(interventionEvent).notTo.beNil();
        expect(OCKCarePlanEventStateCompleted == interventionEvent.state).to.beTruthy();
        
        __block OCKCarePlanEvent *assessmentEvent = nil;
        __block NSError *assessmentEventError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store eventsForActivity:CMHCareTestFactory.assessmentActivity date:CMHCareTestFactory.todayComponents completion:^(NSArray<OCKCarePlanEvent *> *events, NSError *error){
                assessmentEvent = events.firstObject;
                assessmentEventError = error;
                done();
            }];
        });
        
        expect(assessmentEventError).to.beNil();
        expect(assessmentEvent).notTo.beNil();
        expect(OCKCarePlanEventStateCompleted == assessmentEvent.state).to.beTruthy();
        expect(assessmentEvent.result).notTo.beNil();
        expect(assessmentEvent.result.valueString).to.equal(CMHCareTestFactory.assessmentEventResult.valueString);
        expect(assessmentEvent.result.unitString).to.equal(CMHCareTestFactory.assessmentEventResult.unitString);
        //expect(assessmentEvent.result.creationDate.timeIntervalSince1970 == CMHCareTestFactory.assessmentEventResult.creationDate.timeIntervalSince1970).to.beTruthy();
        expect(assessmentEvent.result.userInfo).to.equal(CMHCareTestFactory.assessmentEventResult.userInfo);
    });
    
    it(@"it should sync the user's data when fetched by an admin user", ^{
        CMHCarePlanStore *store = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        NSString *email = [CMHUser currentUser].userData.email;
        NSString *userObjectId = [CMHInternalUser currentUser].objectId;
        
        expect(email).notTo.beNil();
        expect(userObjectId).notTo.beNil();
        
        // Logout of the patient user's account
        
        __block NSError *logoutError = nil;
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] logoutWithCompletion:^(NSError * error) {
                logoutError = error;
                [store clearLocalStore];
                [CMHCarePlanStoreVendor.sharedVendor forgetStores];
                done();
            }];
        });
        
        expect(logoutError).to.beNil();
        expect([CMHUser currentUser].isLoggedIn).to.beFalsy();
        
        // Login to the admin user's account
        
        __block NSError *adminLoginError = nil;
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] loginWithEmail:CMHTestsCareAdminEmail password:CMHTestsCareAdminPassword andCompletion:^(NSError *error) {
                adminLoginError = error;
                done();
            }];
        });
        
        expect(adminLoginError).to.beNil();
        expect([CMHUser currentUser].isLoggedIn).to.beTruthy();
        expect([CMHUser currentUser].userData.userId).notTo.beNil();
        expect([CMHUser currentUser].userData.email).to.equal(CMHTestsCareAdminEmail);
        expect([CMHUser currentUser].userData.isAdmin).to.beTruthy();

        // Fectch all patients as an admin
        
        __block BOOL fetchSuccess = NO;
        __block NSArray *fetchPatients = nil;
        __block NSArray *fetchErrors = nil;
        
        waitUntil(^(DoneCallback done) {
            [CMHCarePlanStore fetchAllPatientsWithCompletion:^(BOOL success, NSArray<OCKPatient *> *patients, NSArray<NSError *> *errors) {
                fetchSuccess = success;
                fetchPatients = patients;
                fetchErrors = errors;
                done();
            }];
        });
        
        expect(fetchSuccess).to.beTruthy();
        expect(fetchPatients).notTo.beNil();
        expect(fetchPatients.count > 0).to.beTruthy();
        expect(fetchErrors).notTo.beNil();
        expect(0 == fetchErrors.count).to.beTruthy();
        
        // Find our original test patient amongst those fetched
        
        OCKPatient *testPatient = nil;
        
        for(OCKPatient *patient in fetchPatients) {
            if([patient.identifier isEqualToString:userObjectId]) {
                testPatient = patient;
                break;
            }
        }
        
        expect(testPatient).notTo.beNil();
        
        // Ensure this admin user is not included in the patients returned
        
        OCKPatient *adminPatient = nil;
        
        for(OCKPatient *patient in fetchPatients) {
            if([patient.identifier isEqualToString:[CMHUser currentUser].userData.userId]) {
                adminPatient = patient;
                break;
            }
        }
        
        expect(adminPatient).to.beNil();
        
        // Ensure the patients user data is available and matches that set up
        
        expect(testPatient.cmh_patientUserData).notTo.beNil();
        expect(testPatient.cmh_patientUserData.isAdmin).to.equal(NO);
        expect(testPatient.cmh_patientUserData.gender).to.equal(CMHCareTestFactory.genderString);
        expect(testPatient.cmh_patientUserData.dateOfBirth).to.equal(CMHCareTestFactory.dateOfBirth);
        expect(testPatient.cmh_patientUserData.userInfo).to.equal(CMHCareTestFactory.userDataUserInfo);
        
        // Ensure the admin can fetch the patient's profile image
        
        __block BOOL photoFetchSuccess = NO;
        __block UIImage *profileImage = nil;
        __block NSError *fetchError = nil;
        
        waitUntil(^(DoneCallback done) {
            [testPatient cmh_fetchProfileImageWithCompletion:^(BOOL success, UIImage *image, NSError *error) {
                photoFetchSuccess = success;
                profileImage = image;
                fetchError = error;
                done();
            }];
        });
        
        expect(photoFetchSuccess).to.beTruthy();
        expect(fetchError).to.beNil();
        expect(profileImage).notTo.beNil();
        expect(profileImage.size.width).to.equal(1.0f);
        expect(profileImage.size.height).to.equal(1.0f);
        
        // Ensure the assessement activity matches that added as a patient
        
        __block BOOL assessmentSuccess = NO;
        __block OCKCarePlanActivity *assessmentActivity = nil;
        __block NSError *asssessmentError = nil;
        
        waitUntil(^(DoneCallback done) {
            [testPatient.store activityForIdentifier:CMHCareTestFactory.assessmentActivity.identifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
                assessmentSuccess = success;
                assessmentActivity = activity;
                asssessmentError = error;
                done();
            }];
        });
        
        expect(assessmentSuccess).to.beTruthy();
        expect(assessmentActivity).notTo.beNil();
        expect(assessmentActivity).to.equal(CMHCareTestFactory.assessmentActivity);
        expect(asssessmentError).to.beNil();
        
        // Ensure the intervention activity matches that added as a patient
        
        __block BOOL interventionSuccess = NO;
        __block OCKCarePlanActivity *interventionActivity = nil;
        __block NSError *interventionError = nil;
        
        waitUntil(^(DoneCallback done) {
            [testPatient.store activityForIdentifier:CMHCareTestFactory.interventionActivity.identifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
                interventionSuccess = success;
                interventionActivity = activity;
                interventionError = error;
                done();
            }];
        });
        
        expect(interventionSuccess).to.beTruthy();
        expect(interventionActivity).notTo.beNil();
        expect(interventionActivity).to.equal(CMHCareTestFactory.interventionActivity);
        expect(interventionError).to.beNil();
        
        // Update the end date for the intervention activity as an admin
        
        __block BOOL endDateSuccess = NO;
        __block OCKCarePlanActivity *endDateActivity = nil;
        __block NSError *endDateError = nil;
        
        waitUntil(^(DoneCallback done) {
            [testPatient.store setEndDate:CMHCareTestFactory.weekInTheFutureComponents forActivity:interventionActivity completion:^(BOOL success, OCKCarePlanActivity *activity, NSError *error) {
                endDateSuccess = success;
                endDateActivity = activity;
                endDateError = error;
                done();
            }];
        });
        
        expect(endDateSuccess).to.beTruthy();
        expect(endDateError).to.beNil();
        expect(endDateActivity).notTo.beNil();
        expect(endDateActivity.schedule.endDate).notTo.beNil();
        expect(endDateActivity.schedule.endDate).to.equal(CMHCareTestFactory.weekInTheFutureComponents);
        
        // Ensure today's intervention event matches that recorded as a patient
        
        __block OCKCarePlanEvent *interventionEvent = nil;
        __block NSError *interventionEventError = nil;
        
        waitUntil(^(DoneCallback done) {
            [testPatient.store eventsForActivity:CMHCareTestFactory.interventionActivity date:CMHCareTestFactory.todayComponents completion:^(NSArray<OCKCarePlanEvent *> *events, NSError *error) {
                interventionEvent = events.firstObject;
                interventionEventError = error;
                done();
            }];
        });
        
        expect(interventionEventError).to.beNil();
        expect(interventionEvent).notTo.beNil();
        expect(OCKCarePlanEventStateCompleted == interventionEvent.state).to.beTruthy();
        
        // Record a change to an intervention event as an admin
        
        __block BOOL interventionUpdateSuccess = NO;
        __block OCKCarePlanEvent *interventionUpdateEvent = nil;
        __block NSError *interventionUpdateError = nil;
        
        waitUntil(^(DoneCallback done) {
            [testPatient.store updateEvent:interventionEvent withResult:nil state:OCKCarePlanEventStateNotCompleted completion:^(BOOL success, OCKCarePlanEvent *event, NSError *error){
                interventionUpdateSuccess = success;
                interventionUpdateEvent = event;
                interventionUpdateError = error;
                done();
            }];
        });
        
        expect(interventionUpdateSuccess).to.beTruthy();
        expect(interventionUpdateError).to.beNil();
        expect(interventionUpdateEvent).notTo.beNil();
        expect(OCKCarePlanEventStateNotCompleted == interventionUpdateEvent.state).to.beTruthy();
        
        // Ensure today's assessement event matches that recorded as a patient
        
        __block OCKCarePlanEvent *assessmentEvent = nil;
        __block NSError *assessmentEventError = nil;
        
        waitUntil(^(DoneCallback done) {
            [testPatient.store eventsForActivity:CMHCareTestFactory.assessmentActivity date:CMHCareTestFactory.todayComponents completion:^(NSArray<OCKCarePlanEvent *> *events, NSError *error){
                assessmentEvent = events.firstObject;
                assessmentEventError = error;
                done();
            }];
        });
        
        expect(assessmentEventError).to.beNil();
        expect(assessmentEvent).notTo.beNil();
        expect(OCKCarePlanEventStateCompleted == assessmentEvent.state).to.beTruthy();
        expect(assessmentEvent.result).notTo.beNil();
        expect(assessmentEvent.result.valueString).to.equal(CMHCareTestFactory.assessmentEventResult.valueString);
        expect(assessmentEvent.result.unitString).to.equal(CMHCareTestFactory.assessmentEventResult.unitString);
        expect(assessmentEvent.result.userInfo).to.equal(CMHCareTestFactory.assessmentEventResult.userInfo);
        
        // Remove the assessment activity as an admin
        
        __block BOOL removeSuccess = NO;
        __block NSError *removeError = nil;
        
        waitUntil(^(DoneCallback done) {
            [testPatient.store removeActivity:assessmentActivity completion:^(BOOL success, NSError *error) {
                removeSuccess = success;
                removeError = error;
                done();
            }];
        });
        
        expect(removeSuccess).to.beTruthy();
        expect(removeError).to.beNil();
        
        // Wait until sync completes to ensure all *pushes* have also cleared
        
        waitUntil(^(DoneCallback done) {
            [(CMHCarePlanStore *)testPatient.store syncFromRemoteWithCompletion:^(BOOL success, NSArray<NSError *> *errors) {
                done();
            }];
        });
        
        // Log out of admin account, clear & forget stores
        
        __block NSError *adminLogoutError = nil;
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] logoutWithCompletion:^(NSError *error) {
                [CMHCarePlanStoreVendor.sharedVendor forgetStores];
                [(CMHCarePlanStore *)testPatient.store clearLocalStore];
                adminLogoutError = error;
                done();
            }];
        });
        
        expect(adminLogoutError).to.beNil();
        expect([CMHUser currentUser].isLoggedIn).to.beFalsy();
        
        // Login as original patient user
        
        __block NSError *loginError = nil;
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] loginWithEmail:email password:CareTestPassword andCompletion:^(NSError * error) {
                loginError = error;
                done();
            }];
        });
        
        expect(loginError).to.beNil();
        expect([CMHUser currentUser].isLoggedIn).to.beTruthy();
    });
    
    it(@"should sync all updates made by the admin user when logged back in as a patient", ^{
        CMHCarePlanStore *store = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        
        // Sync store as patient user
        
        __block BOOL syncSuccess = NO;
        __block NSArray *syncErrors = nil;
        
        waitUntil(^(DoneCallback done) {
            [store syncFromRemoteWithCompletion:^(BOOL success, NSArray<NSError *> *errors) {
                syncSuccess = success;
                syncErrors = errors;
                done();
            }];
        });
        
        expect(syncSuccess).to.beTruthy();
        expect(0 == syncErrors.count).to.beTruthy();
        
        // Ensure the intervention activity matches that updated by the admin
        
        __block BOOL interventionSuccess = NO;
        __block OCKCarePlanActivity *interventionActivity = nil;
        __block NSError *interventionError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store activityForIdentifier:CMHCareTestFactory.interventionActivity.identifier completion:^(BOOL success, OCKCarePlanActivity * activity, NSError * error) {
                interventionSuccess = success;
                interventionActivity = activity;
                interventionError = error;
                done();
            }];
        });
        
        expect(interventionSuccess).to.beTruthy();
        expect(interventionActivity).notTo.beNil();
        expect(interventionActivity.identifier).to.equal(CMHCareTestFactory.interventionActivity.identifier);
        expect(interventionActivity.groupIdentifier).to.equal(CMHCareTestFactory.interventionActivity.groupIdentifier);
        expect(interventionActivity.title).to.equal(CMHCareTestFactory.interventionActivity.title);
        expect(interventionActivity.text).to.equal(CMHCareTestFactory.interventionActivity.text);
        expect(interventionActivity.tintColor).to.equal(CMHCareTestFactory.interventionActivity.tintColor);
        expect(interventionActivity.instructions).to.equal(CMHCareTestFactory.interventionActivity.instructions);
        expect(interventionActivity.type == CMHCareTestFactory.interventionActivity.type).to.beTruthy();
        expect(interventionError).to.beNil();
        expect(interventionActivity.schedule.endDate).notTo.beNil();
        expect(interventionActivity.schedule.endDate).to.equal(CMHCareTestFactory.weekInTheFutureComponents);
        
        // Ensure today's intervention event matches that updated by the admin
        
        __block OCKCarePlanEvent *interventionEvent = nil;
        __block NSError *interventionEventError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store eventsForActivity:interventionActivity date:CMHCareTestFactory.todayComponents completion:^(NSArray<OCKCarePlanEvent *> *events, NSError *error) {
                interventionEvent = events.firstObject;
                interventionEventError = error;
                done();
            }];
        });
        
        expect(interventionEventError).to.beNil();
        expect(interventionEvent).notTo.beNil();
        expect(OCKCarePlanEventStateNotCompleted == interventionEvent.state).to.beTruthy();
        
        // Ensure the assessement activity has been removed by the admin
        
        __block BOOL assessmentSuccess = NO;
        __block OCKCarePlanActivity *assessmentActivity = nil;
        __block NSError *asssessmentError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store activityForIdentifier:CMHCareTestFactory.assessmentActivity.identifier completion:^(BOOL success, OCKCarePlanActivity * _Nullable activity, NSError * _Nullable error) {
                assessmentSuccess = success;
                assessmentActivity = activity;
                asssessmentError = error;
                done();
            }];
        });
        
        expect(assessmentSuccess).to.beTruthy();
        expect(assessmentActivity).to.beNil();
        expect(asssessmentError).to.beNil();
    });
    
    it(@"should fetch a user's profile photo", ^{
        __block BOOL fetchSuccess = NO;
        __block UIImage *profileImage = nil;
        __block NSError *fetchError = nil;
        
        waitUntil(^(DoneCallback done) {
            [[CMHUser currentUser] fetchProfileImageWithCompletion:^(BOOL success, UIImage *image, NSError *error) {
                fetchSuccess = success;
                profileImage = image;
                fetchError = error;
                done();
            }];
        });
        
        expect(fetchSuccess).to.beTruthy();
        expect(fetchError).to.beNil();
        expect(profileImage).notTo.beNil();
        expect(profileImage.size.width).to.equal(1.0f);
        expect(profileImage.size.height).to.equal(1.0f);
    });
    
    it(@"should serialze update and fetch operations", ^{
        CMHCarePlanStore *store = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        
        __block BOOL addSuccess = NO;
        __block NSError * addError = nil;
        __block NSTimeInterval addTime = 0;
        
        __block BOOL firstSyncSuccess = NO;
        __block NSArray *firstSyncErrors = nil;
        __block NSTimeInterval firstSyncTime = 0;
        
        __block BOOL secondSyncSuccess = NO;
        __block NSArray *secondSyncErrors = nil;
        __block NSTimeInterval secondSyncTime = 0;
        
        waitUntil(^(DoneCallback done) {
            
            dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
            
            dispatch_async(backgroundQueue, ^{
                
                dispatch_group_t completionGroup = dispatch_group_create();
                
                dispatch_group_enter(completionGroup);
                dispatch_group_enter(completionGroup);
                dispatch_group_enter(completionGroup);
                
                [store addActivity:CMHCareTestFactory.assessmentActivity completion:^(BOOL success, NSError *error) {
                    addSuccess = success;
                    addError = error;
                    addTime = [NSDate new].timeIntervalSince1970;
                    
                    dispatch_group_leave(completionGroup);
                }];
                
                [store syncFromRemoteWithCompletion:^(BOOL success, NSArray<NSError *> *errors) {
                    firstSyncSuccess = success;
                    firstSyncErrors = errors;
                    firstSyncTime = [NSDate new].timeIntervalSince1970;
                    
                    dispatch_group_leave(completionGroup);
                }];
                
                [store syncFromRemoteWithCompletion:^(BOOL success, NSArray<NSError *> *errors) {
                    secondSyncSuccess = success;
                    secondSyncErrors = errors;
                    secondSyncTime = [NSDate new].timeIntervalSince1970;
                    
                    dispatch_group_leave(completionGroup);
                }];
                
                dispatch_group_wait(completionGroup, DISPATCH_TIME_FOREVER);
                
                done();
            });
        });
        
        expect(addSuccess).to.beTruthy();
        expect(addError).to.beNil();
        
        expect(firstSyncSuccess).to.beTruthy();
        expect(0 == firstSyncErrors.count).to.beTruthy();
        
        expect(secondSyncSuccess).to.beTruthy();
        expect(0 == secondSyncErrors.count).to.beTruthy();
        
        expect(addTime > 0 ).to.beTruthy();
        expect(firstSyncTime > addTime).to.beTruthy();
        
        expect(secondSyncTime > firstSyncTime).to.beTruthy();
    });

    it(@"should clear the local store", ^{
        CMHCarePlanStore *store = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        
        [store clearLocalStore];
        
        __block BOOL activitiesSuccess = NO;
        __block NSArray *allActivities = nil;
        __block NSError *activitiesError = nil;
        
        waitUntil(^(DoneCallback done) {
            [store activitiesWithCompletion:^(BOOL success, NSArray<OCKCarePlanActivity *> *activities, NSError  *error){
                activitiesSuccess = success;
                allActivities = activities;
                activitiesError = error;
                done();
            }];
        });
        
        expect(activitiesSuccess).to.beTruthy();
        expect(allActivities).notTo.beNil();
        expect(0 == allActivities.count).to.beTruthy();
        expect(activitiesError).to.beNil();
    });
    
    afterAll(^{
        CMHCarePlanStore *store = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        CMHTestCleaner *cleaner = [[CMHTestCleaner alloc] init];
        
        waitUntil(^(DoneCallback done) {
            [cleaner deleteAllUserObjectsWithCompletion:^{
                [[CMHUser currentUser] logoutWithCompletion:^(NSError *error){
                    [store clearLocalStore];
                    done();
                }];
            }];
        });
        
        [NSThread sleepForTimeInterval:0.5]; // Apparently, sometimes the app will quit before the NSUserDefaults internal to CMUser synchronizes
    });
});

SpecEnd
