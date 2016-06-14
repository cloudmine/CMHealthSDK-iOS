#import "CMHActivityList.h"
#import "CareKit+CMHealth.h"
#import "CMHInternalUser.h"

@interface CMHActivityList ()
@property (nonatomic, nonnull, readwrite) NSArray <OCKCarePlanActivity *> * activities;
@end

@implementation CMHActivityList

#pragma mark Initializer Overrides

- (instancetype)initWithActivities:(NSArray<OCKCarePlanActivity *> *_Nonnull)activities
{
    NSString *objectId = [NSString stringWithFormat:@"CMHActivityList-%@", [CMHInternalUser currentUser].objectId];
    self = [super initWithObjectId:objectId];

    if (nil == self || nil == activities) return nil;

    self.activities = activities;

    return self;
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    self.activities = [aDecoder decodeObjectForKey:@"activities"];

    if (nil == self.activities) {
        self.activities = @[];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.activities forKey:@"activities"];
}


@end
