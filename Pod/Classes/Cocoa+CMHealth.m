#import "Cocoa+CMHealth.h"
#import <objc/runtime.h>

void cmh_swizzle(Class class, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@implementation UIImage (CMHealth)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cmh_swizzle([self class], @selector(encodeWithCoder:), @selector(cmh_encodeWithCoder:));
    });
}

- (void)cmh_encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder isKindOfClass:[CMObjectEncoder class]]) {
        return;
    }

    [self cmh_encodeWithCoder:aCoder];
}

@end

@implementation UIColor (CMHealth)
@end

@implementation NSUUID (CMHealth)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cmh_swizzle([self class], @selector(initWithCoder:), @selector(initWithCoder_cmh:));
        cmh_swizzle([self class], @selector(encodeWithCoder:), @selector(cmh_encodeWithCoder:));
    });
}

- (void)cmh_encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder isKindOfClass:[CMObjectEncoder class]]) {
        [aCoder encodeObject:self.UUIDString forKey:@"UUIDString"];
        return;
    }

    [self cmh_encodeWithCoder:aCoder];
}

- (instancetype)initWithCoder_cmh:(NSCoder *)decoder
{
    if ([decoder isKindOfClass:[CMObjectDecoder class]]) {
        self = [[NSUUID alloc] initWithUUIDString:[decoder decodeObjectForKey:@"UUIDString"]];
        return self;
    }

    return [self initWithCoder_cmh:decoder];
}

@end

@implementation NSCalendar (CMHealth)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cmh_swizzle([self class], @selector(initWithCoder:), @selector(initWithCoder_cmh:));
        cmh_swizzle([self class], @selector(encodeWithCoder:), @selector(cmh_encodeWithCoder:));
    });
}

- (void)cmh_encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder isKindOfClass:[CMObjectEncoder class]]) {   
        [aCoder encodeObject:self.calendarIdentifier forKey:@"calendarIdentifier"];
        [aCoder encodeObject:self.locale forKey:@"locale"];
        [aCoder encodeObject:self.timeZone forKey:@"timeZone"];
        [aCoder encodeInteger:self.firstWeekday forKey:@"firstWeekday"];
        [aCoder encodeInteger:self.minimumDaysInFirstWeek forKey:@"minimumDaysInFirstWeek"];
        return;
    }

    [self cmh_encodeWithCoder:aCoder];
}

- (instancetype)initWithCoder_cmh:(NSCoder *)decoder
{
    if ([decoder isKindOfClass:[CMObjectDecoder class]]) {
        self = [[NSCalendar alloc] initWithCalendarIdentifier:[decoder decodeObjectForKey:@"calendarIdentifier"]];
        self.locale = [decoder decodeObjectForKey:@"locale"];
        self.timeZone = [decoder decodeObjectForKey:@"timeZone"];
        self.firstWeekday = [decoder decodeIntegerForKey:@"firstWeekday"];
        self.minimumDaysInFirstWeek = [decoder decodeIntegerForKey:@"minimumDaysInFirstWeek"];
        return self;
    }

    return [self initWithCoder_cmh:decoder];
}

@end

@implementation NSTimeZone (CMHealth)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cmh_swizzle([self class], @selector(initWithCoder:), @selector(initWithCoder_cmh:));
        cmh_swizzle([self class], @selector(encodeWithCoder:), @selector(cmh_encodeWithCoder:));
    });
}

- (void)cmh_encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder isKindOfClass:[CMObjectEncoder class]]) {
        [aCoder encodeObject:self.name forKey:@"name"];
        return;
    }

    [self cmh_encodeWithCoder:aCoder];
}

- (instancetype)initWithCoder_cmh:(NSCoder *)decoder
{
    if ([decoder isKindOfClass:[CMObjectDecoder class]]) {
        self = [NSTimeZone timeZoneWithName:[decoder decodeObjectForKey:@"name"]];
        return self;
    }

    return [self initWithCoder_cmh:decoder];
}

@end

@implementation NSLocale (CMHealth)
@end

@implementation NSDateComponents (CMHealth)
@end
