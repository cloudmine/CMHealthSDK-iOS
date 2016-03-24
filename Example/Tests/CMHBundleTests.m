#import <CMHealth/CMHealth.h>

SpecBegin(CMHBundle)

describe(@"CMHAuthViewController", ^{
    it(@"should return a signupViewController", ^{
        CMHAuthViewController *signupVC = [CMHAuthViewController signupViewController];
        expect(signupVC).notTo.beNil();
    });

    it(@"should return a loginViewController", ^{
        CMHAuthViewController *loginVC = [CMHAuthViewController loginViewController];
        expect(loginVC).notTo.beNil();
    });
});

describe(@"ORKKConsentSection (CMHealth)", ^{
    it(@"should return a CloudMine data storage section", ^{
        ORKConsentSection *section = [ORKConsentSection cmh_sectionForSecureCloudMineDataStorage];
        expect(section).notTo.beNil();
    });
});

SpecEnd