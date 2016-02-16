#import <ResearchKit/ResearchKit.h>
#import "CMHResultWrapper.h"

SpecBegin(CMHResultWrapperTests)

describe(@"CMHResultWrapper", ^{
    it(@"should generate dynamic class with wrapped class name embedded", ^{
        Class wrapperClass = [CMHResultWrapper wrapperClassForResultClass:[ORKTaskResult class]];
        expect(NSStringFromClass(wrapperClass)).equal(@"CMHORKTaskResultWrapper");
    });

    it(@"should return the wrapped className", ^{
        Class wrapperClass = [CMHResultWrapper wrapperClassForResultClass:[ORKTaskResult class]];
        expect(NSStringFromClass([ORKTaskResult class])).to.equal([wrapperClass className]);
    });

    it(@"should retain the wrapped result", ^{
        Class wrapperClass = [CMHResultWrapper wrapperClassForResultClass:[ORKResult class]];
        ORKResult *result = [ORKResult new];
        CMHResultWrapper *wrapper = [[wrapperClass alloc] initWithResult:result];
        expect(wrapper.wrappedResult).to.beIdenticalTo(result);
    });

    it(@"should raise an exception if initialized directly with a decoder", ^{
        NSException *caughtException = nil;
        @try {
            CMHResultWrapper *wrapper = [[CMHResultWrapper alloc] initWithCoder:[CMObjectDecoder new]];
            NSLog(@"Wrapper: %@", wrapper);
        } @catch (NSException *e) {
            caughtException = e;
        }

        expect(caughtException).notTo.beNil();
    });

    it(@"should raise an exception if initialized directly with a result", ^{
        NSException *caughtException = nil;
        @try {
            CMHResultWrapper *wrapper = [[CMHResultWrapper alloc] initWithResult:[ORKResult new]];
            NSLog(@"Wrapper: %@", wrapper);
        } @catch (NSException *e) {
            caughtException = e;
        }

        expect(caughtException).notTo.beNil();
    });

    
});

SpecEnd

