#import "CMHCareEventResult.h"
#import "CMHObjectUtilities.h"

@interface CMHCareEventResult ()
@property (nonatomic, nonnull) NSDate *creationDate;
@property (nonatomic, copy, nonnull) NSString *valueString;
@property (nonatomic, copy, nullable) NSString *unitString;
@property (nonatomic, nullable) NSDictionary<NSString *, id<NSCoding>> *userInfo;
@end

@implementation CMHCareEventResult

- (_Nonnull instancetype)initWithEventResult:(OCKCarePlanEventResult *_Nonnull)result
{
    self = [super init];
    if (nil == self || nil == result) return nil;

    self.creationDate = result.creationDate;
    self.valueString = result.valueString;
    self.unitString = result.unitString;
    self.userInfo = result.userInfo;

    return self;
}

#pragma mark Public

- (BOOL)isDataEquivalentOf:(OCKCarePlanEventResult *_Nullable)result
{
    if (nil == result) {
        return NO;
    }

    return [self.valueString isEqualToString:result.valueString] &&
    [self.unitString isEqualToString:result.unitString] &&
    cmhAreObjectsEqual(self.userInfo, result.userInfo);
}

#pragma mark Getter-Setters

- (OCKCarePlanEventResult *)result
{
    // Note: this will change the creation date, which is set internally as the instant the object is initalized
    // There does not seem to be a way to overload this
    return [[OCKCarePlanEventResult alloc] initWithValueString:self.valueString
                                                    unitString:self.unitString
                                                      userInfo:self.userInfo];
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil == self) return nil;

    self.creationDate = [aDecoder decodeObjectForKey:@"creationDate"];
    self.valueString = [aDecoder decodeObjectForKey:@"valueString"];
    self.unitString = [aDecoder decodeObjectForKey:@"unitString"];
    self.userInfo = [aDecoder decodeObjectForKey:@"userInfo"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.creationDate forKey:@"creationDate"];
    [aCoder encodeObject:self.valueString forKey:@"valueString"];
    [aCoder encodeObject:self.unitString forKey:@"unitString"];
    [aCoder encodeObject:self.userInfo forKey:@"userInfo"];
}


@end
