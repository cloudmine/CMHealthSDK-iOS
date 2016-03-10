#import <Foundation/Foundation.h>
#import <CMHealth/Cocoa+CMHealth.h>
#import <CloudMine/CloudMine.h>

SpecBegin(CMHCocoaCategoryTests)

describe(@"NSUUID", ^{
    it(@"should encode and decode properly with an NSCoder", ^{
        NSUUID *origId = [NSUUID new];
        NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:origId];
        NSUUID *codedId = [NSKeyedUnarchiver unarchiveObjectWithData:idData];

        expect(origId == codedId).to.beFalsy();
        expect(origId).to.equal(codedId);
    });

    pending(@"should encode and decode properly with a CMCoder", ^{

    });
});


SpecEnd
