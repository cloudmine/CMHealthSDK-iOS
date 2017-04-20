#import "CMHSyncStamper.h"

static NSString * const _Nonnull CMHSyncKeyPrefix = @"CMHSync-";

@interface CMHSyncStamper ()

@property (nonatomic, nonnull) NSString *cmhIdentifier;
@property (nonatomic, nonnull) NSDateFormatter *cmTimestampFormatter;
@property (nonatomic, nonnull, readonly) NSString *syncKey;

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

- (void)saveLastSyncTime:(NSDate *)date
{
    NSAssert(nil != date, @"Must provide NSDate to %s", __PRETTY_FUNCTION__);
    
    NSString *stamp = [self timestampForDate:date];
    [[NSUserDefaults standardUserDefaults] setObject:stamp forKey:self.syncKey];
}

- (void)forgetSyncTime
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.syncKey];
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

- (NSString *)syncKey
{
    return [NSString stringWithFormat:@"%@%@", CMHSyncKeyPrefix, self.cmhIdentifier];
}

- (NSString *)lastSyncStamp
{
    NSString *savedStamp = [[NSUserDefaults standardUserDefaults] objectForKey:self.syncKey];
    
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
