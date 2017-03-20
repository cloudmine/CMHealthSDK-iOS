#import <CMHealth/CMHealth.h>
#import "CMHTest-Secrets.h"

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
                [[CMHUser currentUser] logoutWithCompletion:^(NSError *error){
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
            [[CMHUser currentUser] signUpWithEmail:@"ben+caretest2@scopelift.co" password:@"password2" andCompletion:^(NSError * _Nullable error) {
                signupError = error;
                done();
            }];
        });
        
        expect(signupError).to.beNil();
    });
    
    it(@"should create a store for the current user and always return the same instance for that store", ^{
        CMHCarePlanStore *storeOne = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        CMHCarePlanStore *storeTwo = [CMHCarePlanStore storeWithPersistenceDirectoryURL:CMHCareIntegrationTestUtils.persistenceDirectory];
        
        expect(storeOne == storeTwo).to.beTruthy();
    });
    
});


SpecEnd
