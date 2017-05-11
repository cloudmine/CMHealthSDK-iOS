#import "CMHCareActivity.h"
#import "CMHConstants_internal.h"

@interface CMHCareActivity ()

@property (nonatomic, nonnull, readwrite) OCKCarePlanActivity *ckActivity;
@property (nonatomic, nonnull) NSString *cmhOwnerId;

@end

@implementation CMHCareActivity

#pragma mark Initialization

- (instancetype)initWithActivity:(nonnull OCKCarePlanActivity *)activity andUserId:(nonnull NSString *)cmhIdentifier;
{
    return [self initWithActivity:activity userId:cmhIdentifier isDeleted:NO];
}

- (instancetype)initWithActivity:(OCKCarePlanActivity *)activity userId:(NSString *)cmhIdentifier isDeleted:(BOOL)isDeleted
{
    NSAssert(nil != activity, @"%@ cannot be initialized without an activity", [self class]);
    NSAssert(nil != cmhIdentifier, @"%@ cannot be initialized without a user object id", [self class]);
    
    NSString *cmhObjectId = nil;
    
    if (isDeleted) {
        cmhObjectId = [NSString stringWithFormat:@"%@-%@%@%@", activity.identifier, cmhIdentifier, CMHActivityDeletedSeperator, [NSUUID new].UUIDString];
    } else {
        cmhObjectId = [NSString stringWithFormat:@"%@-%@", activity.identifier, cmhIdentifier];
    }
    
    self = [super initWithObjectId:cmhObjectId];
    if (nil == self) return nil;
    
    _ckActivity = activity;
    _cmhOwnerId = [cmhIdentifier copy];
    _isDeleted = isDeleted;
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) { return nil; }
    
    _ckActivity = [aDecoder decodeObjectForKey:@"ckActivity"];
    _cmhOwnerId = [aDecoder decodeObjectForKey:CMHOwningUserKey];
    _isDeleted = [aDecoder decodeBoolForKey:@"isDeleted"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.ckActivity forKey:@"ckActivity"];
    [aCoder encodeObject:self.cmhOwnerId forKey:CMHOwningUserKey];
    [aCoder encodeBool:self.isDeleted forKey:@"isDeleted"];
}

@end
