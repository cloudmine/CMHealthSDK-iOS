#import <Foundation/Foundation.h>
#import <CMHealth/CMHealth.h>
#import <CMHealth/CMHErrorUtilities.h>

SpecBegin(CMHErrorUtilities)

describe(@"CMHErrorUtilities", ^{
    it(@"Should produce an error with the correct domain, and given code and description", ^{
        NSError *testError = [CMHErrorUtilities errorWithCode:CMHErrorUnknown localizedDescription:@"Test Error Description"];

        expect(testError.code).to.equal(CMHErrorUnknown);
        expect(testError.domain).to.equal(CMHErrorDomain);
        expect(testError.localizedDescription).to.equal(@"Test Error Description");
    });
});

SpecEnd