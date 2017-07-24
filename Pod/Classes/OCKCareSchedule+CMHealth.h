#import <CareKit/CareKit.h>

static inline BOOL
areEqual(id _Nullable obj1, id _Nullable obj2)
{
    if (obj1 == obj2) {
        return YES;
    }
    
    if (nil == obj1 || nil == obj2) {
        return NO;
    }
    
    return [obj1 isEqual:obj2];
}

@interface OCKCareSchedule (CMHealthCompare)

- (BOOL)isEqualExceptEndDate:(nullable OCKCareSchedule *)other;

@end
