#import <CMHealth/CMHealth.h>
#import "CMHTest-Secrets.h"
#import "CMHCareTestFactory.h"
#import <CMHealth/CMHCareActivity.h>
#import <CMHealth/CMHInternalUser.h>
#import <CMHealth/CMHCareObjectSaver.h>

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
        
        waitUntil(^(DoneCallback done) {
            NSString *unixTime = [NSNumber numberWithInt:(int)[NSDate new].timeIntervalSince1970].stringValue;
            NSString *emailAddress = [NSString stringWithFormat:@"cmcare+%@@cloudmineinc.com", unixTime];
            
            [[CMHUser currentUser] signUpWithEmail:emailAddress password:CareTestPassword andCompletion:^(NSError * _Nullable error) {
                signupError = error;
                done();
            }];
        });
        
        expect(signupError).to.beNil();
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
       
    it(@"should create a store for the current user and always return the same instance for that store", ^{
        CMHCarePlanStore *storeOne = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        CMHCarePlanStore *storeTwo = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        
        expect(storeOne == storeTwo).to.beTruthy();
    });
    
    afterAll(^{
        CMHCarePlanStore *store = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        [store clearLocalStore];
        [[CMHUser currentUser] logoutWithCompletion:nil];
    });
});


SpecEnd
