#import "CMHActivityList.h"
#import "CareKit+CMHealth.h"

@interface CMHActivityList ()
@property (nonatomic, nonnull, readwrite) NSArray <OCKCarePlanActivity *> * activities;
@end

@implementation CMHActivityList

#pragma mark Initializer Overrides

- (instancetype)init
{
    self = [super init];
    if (nil == self) return nil;

    self.activities = @[];

    return self;
}

- (instancetype)initWithObjectId:(NSString *)theObjectId
{
    self = [super initWithObjectId:theObjectId];
    if (nil == self) return nil;

    self.activities = @[];

    return self;
}

- (instancetype)initWithActivities:(NSArray<OCKCarePlanActivity *> *_Nonnull)activities
{
    self = [self init];
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
