#import <ResearchKit/ResearchKit.h>
#import "CMHTest-Secrets.h"

SpecBegin(CMHealth)

describe(@"CMHealthIntegration", ^{

    it(@"should have set up your App Id and API Key constants", ^{
        NSLog(@"%@", CMHTestsAppId);

        expect(CMHTestsAppId.length).to.beGreaterThan(0);
        expect(CMHTestsAppId).notTo.equal(@"REPLACE_WITH_AN_APP_ID_TO_USE_FOR_TESTING");

        expect(CMHTestsAPIKey.length).to.beGreaterThan(0);
        expect(CMHTestsAPIKey).notTo.equal(@"REPLACE_WITH_API_KEY");
    });

    it(@"should pass", ^{
        expect(YES).to.beTruthy();
    });
});

SpecEnd

