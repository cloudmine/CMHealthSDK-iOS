#import <ResearchKit/ResearchKit.h>
#import "CMHResultWrapper.h"

SpecBegin(InitialSpecs)

describe(@"CMHResultWrapper", ^{
    it(@"should generate dynamic class with wrapped class name embedded", ^{
        Class wrapperClass = [CMHResultWrapper wrapperClassForResultClass:[ORKTaskResult class]];
        expect(NSStringFromClass(wrapperClass)).equal(@"CMHORKTaskResultWrapper");
    });
});

describe(@"these will pass", ^{
    
    it(@"can do maths", ^{
        expect(1).beLessThan(23);
    });
    
    it(@"can read", ^{
        expect(@"team").toNot.contain(@"I");
    });
    
    it(@"will wait and succeed", ^{
        waitUntil(^(DoneCallback done) {
            done();
        });
    });
});

SpecEnd

