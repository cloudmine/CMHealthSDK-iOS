#import <Foundation/Foundation.h>
#import <CMHealth/Cocoa+CMHealth.h>
#import <CloudMine/CloudMine.h>

@interface CMHTestUUIDWrapper : CMObject
- (instancetype)initWithUUID:(NSUUID *)uuid;
@property (nonatomic) NSUUID *uuid;
@end

@implementation CMHTestUUIDWrapper

- (instancetype)initWithUUID:(NSUUID *)uuid
{
    self = [super init];
    if (nil == self) return nil;

    self.uuid = uuid;

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    self.uuid = [aDecoder decodeObjectForKey:@"uuid"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
}

@end

SpecBegin(CMHCocoaCategoryTests)

describe(@"NSUUID", ^{
    it(@"should encode and decode properly with NSCoder", ^{
        NSUUID *origId = [NSUUID new];
        NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:origId];
        NSUUID *codedId = [NSKeyedUnarchiver unarchiveObjectWithData:idData];

        expect(origId == codedId).to.beFalsy();
        expect(origId).to.equal(codedId);
    });

    it(@"should encode and decode properly with CMCoder", ^{
        CMHTestUUIDWrapper *origWrapper = [[CMHTestUUIDWrapper alloc] initWithUUID:[NSUUID new]];
        NSDictionary *encodedObjects = [CMObjectEncoder encodeObjects:@[origWrapper]];
        CMHTestUUIDWrapper *codedWrapper = [CMObjectDecoder decodeObjects:encodedObjects].firstObject;

        expect(origWrapper == codedWrapper).to.beFalsy();
        expect(origWrapper.uuid == codedWrapper.uuid).to.beFalsy();
        expect(codedWrapper.uuid).to.equal(origWrapper.uuid);
        expect(encodedObjects[origWrapper.objectId][@"uuid"][@"UUIDString"]).to.equal(origWrapper.uuid.UUIDString);
    });
});

describe(@"UIImage", ^{
    it(@"should encode and decode properly with NSCoder", ^{
        // Bug in Cocoa? See: http://stackoverflow.com/questions/26213575/unarchive-uiimage-object-returns-cgsizezero-image-using-nskeyedunarchiver-on-ios
        UIImage *assetImage = [UIImage imageNamed:@"Test-Signature-Image.png"];

        UIImage *origImage = [UIImage imageWithCGImage:assetImage.CGImage scale:assetImage.scale orientation:assetImage.imageOrientation];
        NSData *imageData = [NSKeyedArchiver archivedDataWithRootObject:origImage];
        UIImage *codedImage = [NSKeyedUnarchiver unarchiveObjectWithData:imageData];

        expect(origImage == codedImage).to.beFalsy();
        expect(codedImage.size.width).to.equal(origImage.size.width);
        expect(codedImage.size.height).to.equal(origImage.size.height);
    });
});


SpecEnd
