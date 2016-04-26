#import <Foundation/Foundation.h>
#import <CMHealth/Cocoa+CMHealth.h>
#import <CloudMine/CloudMine.h>

@interface CMHTestCodingWrapper : CMObject
- (instancetype)initWithUUID:(NSUUID *)uuid;
- (instancetype)initWithImage:(UIImage *)image;
@property (nonatomic) NSUUID *uuid;
@property (nonatomic) UIImage *image;
@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSTimeZone *timeZone;
@property (nonatomic) NSLocale *locale;
@property (nonatomic) NSDateComponents *comps;
@end

@implementation CMHTestCodingWrapper

- (instancetype)initWithUUID:(NSUUID *)uuid
{
    self = [super init];
    if (nil == self) return nil;

    self.uuid = uuid;

    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (nil == self) return nil;

    self.image = image;

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
    self.image = [aDecoder decodeObjectForKey:@"image"];
    self.calendar = [aDecoder decodeObjectForKey:@"calendar"];
    self.timeZone = [aDecoder decodeObjectForKey:@"timeZone"];
    self.locale = [aDecoder decodeObjectForKey:@"locale"];
    self.comps = [aDecoder decodeObjectForKey:@"comps"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
    [aCoder encodeObject:self.image forKey:@"image"];
    [aCoder encodeObject:self.calendar forKey:@"calendar"];
    [aCoder encodeObject:self.timeZone forKey:@"timeZone"];
    [aCoder encodeObject:self.locale forKey:@"locale"];
    [aCoder encodeObject:self.comps forKey:@"comps"];
}

#pragma mark Factory Convenience Methods

+ (NSDateComponents *)testDateComponents
{
    NSDateComponents *comps = [NSDateComponents new];
    comps.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierHebrew];
    comps.timeZone = [NSTimeZone timeZoneWithName:@"Pacific/Honolulu"];
    comps.era = 1;
    comps.year = 5000;
    comps.month = 10;
    comps.day = 12;
    comps.hour = 7;
    comps.minute = 16;
    comps.second = 6;
    comps.nanosecond = 4;
    comps.weekday = 3;
    comps.weekdayOrdinal = 2;
    comps.quarter = 2;
    comps.weekOfMonth = 1;
    comps.weekOfYear = 40;
    comps.yearForWeekOfYear = 8;
    comps.leapMonth = NO;

    return comps;
}

+ (BOOL)isEquivalentToTest:(NSDateComponents *)comps
{
    NSDateComponents *testComps = [self testDateComponents];

    BOOL isEqual = YES;
    isEqual = isEqual && [comps.calendar.calendarIdentifier isEqualToString:testComps.calendar.calendarIdentifier];
    isEqual = isEqual && [comps.timeZone.name isEqualToString:testComps.timeZone.name];
    isEqual = isEqual && comps.era == testComps.era;
    isEqual = isEqual && comps.year == testComps.year;
    isEqual = isEqual && comps.month == testComps.month;
    isEqual = isEqual && comps.day == testComps.day;
    isEqual = isEqual && comps.hour == testComps.hour;
    isEqual = isEqual && comps.minute == testComps.minute;
    isEqual = isEqual && comps.second == testComps.second;
    isEqual = isEqual && comps.nanosecond == testComps.nanosecond;
    isEqual = isEqual && comps.weekday == testComps.weekday;
    isEqual = isEqual && comps.weekdayOrdinal == testComps.weekdayOrdinal;
    isEqual = isEqual && comps.quarter == testComps.quarter;
    isEqual = isEqual && comps.weekOfMonth == testComps.weekOfMonth;
    isEqual = isEqual && comps.weekOfYear == testComps.weekOfYear;
    isEqual = isEqual && comps.yearForWeekOfYear == testComps.yearForWeekOfYear;
    isEqual = isEqual && comps.leapMonth == testComps.leapMonth;

    return isEqual;
}

@end

SpecBegin(CMHCocoaCategoryTests)

#pragma mark NSUUID

describe(@"NSUUID", ^{
    it(@"should encode and decode properly with NSCoder", ^{
        NSUUID *origId = [NSUUID new];
        NSData *idData = [NSKeyedArchiver archivedDataWithRootObject:origId];
        NSUUID *codedId = [NSKeyedUnarchiver unarchiveObjectWithData:idData];

        expect(origId == codedId).to.beFalsy();
        expect(origId).to.equal(codedId);
    });

    it(@"should encode and decode properly with CMCoder", ^{
        CMHTestCodingWrapper *origWrapper = [[CMHTestCodingWrapper alloc] initWithUUID:[NSUUID new]];
        NSDictionary *encodedObjects = [CMObjectEncoder encodeObjects:@[origWrapper]];
        CMHTestCodingWrapper *codedWrapper = [CMObjectDecoder decodeObjects:encodedObjects].firstObject;

        expect(origWrapper == codedWrapper).to.beFalsy();
        expect(origWrapper.uuid == codedWrapper.uuid).to.beFalsy();
        expect(codedWrapper.uuid).to.equal(origWrapper.uuid);
        expect(encodedObjects[origWrapper.objectId][@"uuid"][@"UUIDString"]).to.equal(origWrapper.uuid.UUIDString);
    });
});

#pragma mark UIImage

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

    it(@"should intentionally drop the image data with CMCoder", ^{
        CMHTestCodingWrapper *origWrapper = [[CMHTestCodingWrapper alloc] initWithImage:[UIImage imageNamed:@"Test-Signature-Image.png"]];
        NSDictionary *encodedObjects = [CMObjectEncoder encodeObjects:@[origWrapper]];
        CMHTestCodingWrapper *codedWrapper = [CMObjectDecoder decodeObjects:encodedObjects].firstObject;

        expect(origWrapper == codedWrapper).to.beFalsy();
        expect(encodedObjects[origWrapper.objectId][@"image"][CMInternalClassStorageKey]).to.equal(@"UIImage");
        expect(codedWrapper.image).to.beNil();
    });
});

#pragma mark NSCalendar

describe(@"NSCalendar", ^{
    it(@"should encode and decode properly with NSCoder", ^{
        NSCalendar *origCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierChinese];
        NSData *calendarData = [NSKeyedArchiver archivedDataWithRootObject:origCalendar];
        NSCalendar *codedCalendar = [NSKeyedUnarchiver unarchiveObjectWithData:calendarData];

        expect(origCalendar == codedCalendar).to.beFalsy();
        expect(origCalendar.calendarIdentifier == codedCalendar.calendarIdentifier).to.beTruthy();
        expect(origCalendar).to.equal(codedCalendar);
    });

    it(@"should encode and decode properly with CMCoder", ^{
        CMHTestCodingWrapper *origWrapper = [CMHTestCodingWrapper new];
        origWrapper.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierChinese];
        NSDictionary *encodedObjects = [CMObjectEncoder encodeObjects:@[origWrapper]];
        CMHTestCodingWrapper *codedWrapper = [CMObjectDecoder decodeObjects:encodedObjects].firstObject;

        expect(origWrapper == codedWrapper).to.beFalsy();
        expect(origWrapper.calendar == codedWrapper.calendar).to.beFalsy();
        expect([codedWrapper.calendar.calendarIdentifier isEqualToString:origWrapper.calendar.calendarIdentifier]).to.beTruthy();
        expect(origWrapper.calendar).to.equal(codedWrapper.calendar);
    });
});

#pragma mark NSTimeZone

describe(@"NSTimeZone", ^{
    it(@"should encode and decode properly with NSCoder", ^{
        NSTimeZone *origZone = [NSTimeZone timeZoneWithName:@"Pacific/Honolulu"];
        NSData *zoneData = [NSKeyedArchiver archivedDataWithRootObject:origZone];
        NSTimeZone *codedZone = [NSKeyedUnarchiver unarchiveObjectWithData:zoneData];

        expect(origZone == codedZone).to.beFalsy();
        expect([origZone.name isEqualToString:codedZone.name]).to.beTruthy();
        expect(origZone).to.equal(codedZone);
    });

    it(@"should encode and decode properly with CMCoder", ^{
        CMHTestCodingWrapper *origWrapper = [CMHTestCodingWrapper new];
        origWrapper.timeZone = [NSTimeZone timeZoneWithName:@"Pacific/Honolulu"];
        NSDictionary *encodedObjects = [CMObjectEncoder encodeObjects:@[origWrapper]];
        CMHTestCodingWrapper *codedWrapper = [CMObjectDecoder decodeObjects:encodedObjects].firstObject;

        expect(origWrapper == codedWrapper).to.beFalsy();
        expect(origWrapper.timeZone == codedWrapper.timeZone).to.beFalsy();
        expect([origWrapper.timeZone.name isEqualToString:codedWrapper.timeZone.name]).to.beTruthy();
        expect(origWrapper.timeZone).to.equal(codedWrapper.timeZone);
    });
});

#pragma mark NSLocale

describe(@"NSLocale", ^{
    it(@"should encode and decode properly with NSCoder", ^{
        NSLocale *origLocale = [NSLocale localeWithLocaleIdentifier:[NSLocale canonicalLocaleIdentifierFromString:@"it_IT"]];
        NSData *localeData = [NSKeyedArchiver archivedDataWithRootObject:origLocale];
        NSLocale *codedLocale = [NSKeyedUnarchiver unarchiveObjectWithData:localeData];

        expect(origLocale).notTo.beNil();
        expect([origLocale.localeIdentifier isEqualToString:codedLocale.localeIdentifier]).to.beTruthy();
        expect(origLocale).to.equal(codedLocale);
    });

    it(@"should econde and decode properly with CMCoder", ^{
        CMHTestCodingWrapper *origWrapper = [CMHTestCodingWrapper new];
        origWrapper.locale = [NSLocale localeWithLocaleIdentifier:[NSLocale canonicalLocaleIdentifierFromString:@"it_IT"]];
        NSDictionary *encodedObjects = [CMObjectEncoder encodeObjects:@[origWrapper]];
        CMHTestCodingWrapper *codedWrapper = [CMObjectDecoder decodeObjects:encodedObjects].firstObject;

        expect(codedWrapper).notTo.beNil();
        expect(origWrapper == codedWrapper).to.beFalsy();
        expect([origWrapper.locale.localeIdentifier isEqualToString:codedWrapper.locale.localeIdentifier]).to.beTruthy();
    });
});

#pragma mark NSDateComponents

describe(@"NSDateComponents", ^{
    it(@"should encode and decode properly with NSCoder", ^{
        NSDateComponents *origComps = [CMHTestCodingWrapper testDateComponents];
        NSData *compsData = [NSKeyedArchiver archivedDataWithRootObject:origComps];
        NSDateComponents *codedComps = [NSKeyedUnarchiver unarchiveObjectWithData:compsData];

        expect(origComps == codedComps).to.beFalsy();
        expect([CMHTestCodingWrapper isEquivalentToTest:codedComps]).to.beTruthy();
    });

    it(@"should encode and decode properly with CMCoder", ^{
        CMHTestCodingWrapper *origWrapper = [CMHTestCodingWrapper new];
        origWrapper.comps = [CMHTestCodingWrapper testDateComponents];
        NSDictionary *encodedObjects = [CMObjectEncoder encodeObjects:@[origWrapper]];
        CMHTestCodingWrapper *codedWrapper = [CMObjectDecoder decodeObjects:encodedObjects].firstObject;

        expect(codedWrapper).notTo.beNil();
        expect(origWrapper == codedWrapper).to.beFalsy();
        expect([CMHTestCodingWrapper isEquivalentToTest:codedWrapper.comps]).to.beTruthy();
    });
});

SpecEnd
