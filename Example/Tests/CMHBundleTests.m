#import <CMHealth/CMHealth.h>

SpecBegin(CMHBundle)

describe(@"ORKKConsentSection (CMHealth)", ^{
    it(@"should return a CloudMine data storage section", ^{
        ORKConsentSection *section = [ORKConsentSection cmh_sectionForSecureCloudMineDataStorage];
        expect(section).notTo.beNil();
    });
});

SpecEnd