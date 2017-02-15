#import "CMHCareEvent.h"
#import "CMHCareEventResult.h"
#import "OCKCarePlanEvent+CMHealth.h"
#import "CareKit+CMHealth.h"
#import "CMHConstants_internal.h"

@interface CMHCareEvent ()
@property (nonatomic, nonnull, readwrite) OCKCarePlanEvent *ckEvent;
@property (nonatomic, nonnull) NSString *cmhOwnerId;
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
    
    _ckEvent = event;
    _cmhOwnerId = [cmhIdentifier copy];
    
    return self;
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    _ckEvent = [aDecoder decodeObjectForKey:@"ckEvent"];
    _cmhOwnerId = [aDecoder decodeObjectForKey:CMHOwningUserKey];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.ckEvent forKey:@"ckEvent"];
    [aCoder encodeObject:self.cmhOwnerId forKey:CMHOwningUserKey];
}

@end
