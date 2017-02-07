#import "CMHCareEvent.h"
#import "CMHCareEventResult.h"
#import "OCKCarePlanEvent+CMHealth.h"
#import "CareKit+CMHealth.h"

@interface CMHCareEvent ()
@property (nonatomic, nonnull, readwrite) OCKCarePlanEvent *ckEvent;
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
    
    return self;
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    _ckEvent = [aDecoder decodeObjectForKey:@"ckEvent"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.ckEvent forKey:@"ckEvent"];
}

@end
