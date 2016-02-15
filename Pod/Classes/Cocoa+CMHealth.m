#import "Cocoa+CMHealth.h"
#import <objc/runtime.h>

void acm_swizzle(Class class, SEL originalSelector, SEL swizzledSelector)
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
        acm_swizzle([self class], @selector(encodeWithCoder:), @selector(acm_encodeWithCoder:));
    });
}

- (void)acm_encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder isKindOfClass:[CMObjectEncoder class]]) {
        return;
    }

    [self acm_encodeWithCoder:aCoder];
}

@end

@implementation NSUUID (CMHealth)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        acm_swizzle([self class], @selector(initWithCoder:), @selector(initWithCoder_acm:));
        acm_swizzle([self class], @selector(encodeWithCoder:), @selector(acm_encodeWithCoder:));
    });
}

- (void)acm_encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder isKindOfClass:[CMObjectEncoder class]]) {
        [aCoder encodeObject:self.UUIDString forKey:@"UUIDString"];
        return;
    }

    [self acm_encodeWithCoder:aCoder];
}

- (instancetype)initWithCoder_acm:(NSCoder *)decoder
{
    if ([decoder isKindOfClass:[CMObjectDecoder class]]) {
        self = [[NSUUID alloc] initWithUUIDString:[decoder decodeObjectForKey:@"UUIDString"]];
        return self;
    }

    return [self initWithCoder_acm:decoder];
}

@end