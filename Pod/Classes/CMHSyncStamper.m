#import "CMHSyncStamper.h"

static NSString * const _Nonnull CMHEventSyncKeyPrefix = @"CMHEventSync-";
static NSString * const _Nonnull CMHActivitySyncKeyPrefix = @"CMHActivitySync-";

@interface CMHSyncStamper ()

@property (nonatomic, nonnull) NSString *cmhIdentifier;
@property (nonatomic, nonnull) NSDateFormatter *cmTimestampFormatter;
@property (nonatomic, nonnull, readonly) NSString *eventSyncKey;
@property (nonatomic, nonnull, readonly) NSString *activitySyncKey;

@end

@implementation CMHSyncStamper

#pragma mark Initialization

- (instancetype)initWithCMHIdentifier:(NSString *)cmhIdentifier
{
    NSAssert(nil != cmhIdentifier, @"Cannot initialize %@ without an identifier parameter", [CMHSyncStamper class]);
    
    self = [super init];
    if (nil == self) { return nil; }
    
    _cmhIdentifier = cmhIdentifier;
    
    return self;
}

#pragma mark Public

- (void)saveEventLastSyncTime:(NSDate *)date
{
    NSAssert(nil != date, @"Must provide NSDate to %@", __PRETTY_FUNCTION__);
    
    NSString *stamp = [self timestampForDate:date];
    [[NSUserDefaults standardUserDefaults] setObject:stamp forKey:self.eventSyncKey];
}

- (void)saveActivityLastSyncTime:(NSDate *)date
{
    NSAssert(nil != date, @"Must provide NSDate to %@", __PRETTY_FUNCTION__);
    
    NSString *stamp = [self timestampForDate:date];
    [[NSUserDefaults standardUserDefaults] setObject:stamp forKey:self.activitySyncKey];
}

- (void)forgetSyncTimes
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.eventSyncKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.activitySyncKey];
}

#pragma mark Getters-Setters

- (NSDateFormatter *)cmTimestampFormatter
{
    if (nil == _cmTimestampFormatter) {
        _cmTimestampFormatter = [NSDateFormatter new];
        _cmTimestampFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
        _cmTimestampFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _cmTimestampFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    }
    
    return _cmTimestampFormatter;
}

- (NSString *)eventSyncKey
{
    return [NSString stringWithFormat:@"%@%@", CMHEventSyncKeyPrefix, self.cmhIdentifier];
}

- (NSString *)eventLastSyncStamp
{
    NSString *savedStamp = [[NSUserDefaults standardUserDefaults] objectForKey:self.eventSyncKey];
    
    if (nil == savedStamp) {
        NSDate *longAgo = [NSDate dateWithTimeIntervalSince1970:0];
        return [self timestampForDate:longAgo];
    }
    
    return savedStamp;
}

- (NSString *)activitySyncKey
{
    return [NSString stringWithFormat:@"%@%@", CMHActivitySyncKeyPrefix, self.cmhIdentifier];
}

- (NSString *)activityLastSyncStamp
{
    NSString *savedStamp = [[NSUserDefaults standardUserDefaults] objectForKey:self.activitySyncKey];
    
    if (nil == savedStamp) {
        NSDate *longAgo = [NSDate dateWithTimeIntervalSince1970:0];
        return [self timestampForDate:longAgo];
    }
    
    return savedStamp;
}

#pragma mark Helpers

- (NSString *)timestampForDate:(NSDate *)date
{
    return [self.cmTimestampFormatter stringFromDate:date];
}
@end
