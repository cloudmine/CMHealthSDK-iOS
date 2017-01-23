#import "CMHCareEvent.h"
#import "CMHCareEventResult.h"
#import "OCKCarePlanEvent+CMHealth.h"
#import "CareKit+CMHealth.h"

@interface CMHCareEvent ()
@property (nonatomic, readwrite) NSUInteger occurrenceIndexOfDay;
@property (nonatomic, readwrite) NSUInteger numberOfDaysSinceStart;
@property (nonatomic, nonnull, readwrite) NSDateComponents *date;
@property (nonatomic, nonnull, readwrite) OCKCarePlanActivity *activity;
@property (nonatomic, nonnull, readwrite) NSString *stateString;
@property (nonatomic, nullable) CMHCareEventResult *resultWrapper;
@end

@implementation CMHCareEvent

# pragma mark Initializer

- (_Nonnull instancetype)initWithEvent:(OCKCarePlanEvent *_Nonnull)event andUserId:(NSString *_Nonnull)cmhIdentifier;
{
    NSAssert(nil != event, @"%@ cannot be initialized without an event", [self class]);
    NSAssert(nil != cmhIdentifier, @"%@ cannot be intitialized without a user object id", [self class]);
    
    NSString *cmhObjectId = [NSString stringWithFormat:@"%@-%@", event.cmh_uniqueId, cmhIdentifier];

    self = [super initWithObjectId:cmhObjectId];
    if (nil == self) return nil;

    _occurrenceIndexOfDay = event.occurrenceIndexOfDay;
    _numberOfDaysSinceStart = event.numberOfDaysSinceStart;
    _date = event.date;
    _activity = event.activity;
    _stateString = [CMHCareEvent stateStringFromState:event.state];

    if (nil != event.result) {
        _resultWrapper = [[CMHCareEventResult alloc] initWithEventResult:event.result];
    }

    return self;
}

#pragma mark Public

- (BOOL)isDataEquivalentOf:(OCKCarePlanEvent *_Nullable)event
{
    if (nil == event) {
        return NO;
    }

    BOOL isEquivalentData = self.occurrenceIndexOfDay == event.occurrenceIndexOfDay &&
    self.numberOfDaysSinceStart == event.numberOfDaysSinceStart &&
    [self.date isEqual:event.date] &&
    [self.activity isDataEquivalentOf:event.activity] &&
    self.state == event.state;

    if (nil == self.result && nil == event.result) {
        return isEquivalentData;
    }

    return isEquivalentData && [self.resultWrapper isDataEquivalentOf:event.result];
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    self.occurrenceIndexOfDay = [aDecoder decodeIntegerForKey:@"occurrenceIndexOfDay"];
    self.numberOfDaysSinceStart = [aDecoder decodeIntegerForKey:@"numberOfDaysSinceStart"];
    self.date = [aDecoder decodeObjectForKey:@"date"];
    self.activity = [aDecoder decodeObjectForKey:@"activity"];
    self.stateString = [aDecoder decodeObjectForKey:@"state"];
    self.resultWrapper = [aDecoder decodeObjectForKey:@"result"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInteger:self.occurrenceIndexOfDay forKey:@"occurrenceIndexOfDay"];
    [aCoder encodeInteger:self.numberOfDaysSinceStart forKey:@"numberOfDaysSinceStart"];
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeObject:self.activity forKey:@"activity"];
    [aCoder encodeObject:self.stateString forKey:@"state"];
    [aCoder encodeObject:self.resultWrapper forKey:@"result"];
}

#pragma mark Getters-Setters

- (OCKCarePlanEventResult *)result
{
    return self.resultWrapper.result;
}

- (OCKCarePlanEventState)state
{
    return [CMHCareEvent stateFromString:self.stateString];
}

#pragma mark Private

+ (NSString *_Nonnull)stateStringFromState:(OCKCarePlanEventState)state
{
    switch (state) {
        case OCKCarePlanEventStateInitial:
            return @"OCKCarePlanEventStateInitial";
        case OCKCarePlanEventStateNotCompleted:
            return @"OCKCarePlanEventStateNotCompleted";
        case OCKCarePlanEventStateCompleted:
            return @"OCKCarePlanEventStateCompleted";
        default:
            return @"";
    }
}

+ (OCKCarePlanEventState)stateFromString:(NSString * _Nonnull)stateString
{
    if ([@"OCKCarePlanEventStateInitial" isEqualToString:stateString]) {
        return OCKCarePlanEventStateInitial;
    } else if ([@"OCKCarePlanEventStateNotCompleted" isEqualToString:stateString]) {
        return OCKCarePlanEventStateNotCompleted;
    } else if ([@"OCKCarePlanEventStateCompleted" isEqualToString:stateString]) {
        return OCKCarePlanEventStateCompleted;
    } else {
        return -1;
    }
}


@end
