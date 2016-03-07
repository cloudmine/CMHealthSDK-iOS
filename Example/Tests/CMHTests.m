#import <CMHealth/CMHealth.h>
#import "CMHTest-Secrets.h"

SpecBegin(CMHealth)

describe(@"CMHealthIntegration", ^{

    beforeAll(^{
        expect(CMHTestsAppId.length).to.beGreaterThan(0);
        expect(CMHTestsAppId).notTo.equal(@"REPLACE_WITH_AN_APP_ID_TO_USE_FOR_TESTING");

        expect(CMHTestsAPIKey.length).to.beGreaterThan(0);
        expect(CMHTestsAPIKey).notTo.equal(@"REPLACE_WITH_API_KEY");

        [CMHealth setAppIdentifier:CMHTestsAppId appSecret:CMHTestsAPIKey];

        [Expecta setAsynchronousTestTimeout:5];
        setAsyncSpecTimeout(5);

        waitUntil(^(DoneCallback done) {
            if([CMHUser currentUser].isLoggedIn) {
                [[CMHUser currentUser] logoutWithCompletion:^(NSError *error){
                    done();
                }];
            } else {
                done();
            }
        });

        expect([CMHUser currentUser].isLoggedIn).to.equal(NO);
    });

    it(@"should create a user and sign them up", ^{
        NSString *unixTime = [NSNumber numberWithInt:(int)[NSDate new].timeIntervalSince1970].stringValue;
        NSString *emailAddress = [NSString stringWithFormat:@"cmhealth+%@@cloudmineinc.com", unixTime];

        [[CMHUser currentUser] signUpWithEmail:emailAddress password:@"test-password1" andCompletion:^(NSError *error) {

        }];

        expect([CMHUser currentUser].isLoggedIn).will.equal(YES);
        expect([CMHUser currentUser].userData.email).will.equal(emailAddress);
    });
    

    it(@"should pass", ^{
        expect(YES).to.beTruthy();
    });
});

SpecEnd

