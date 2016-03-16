#import "CMHInternalProfile.h"

@implementation CMHInternalProfile

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    self.givenName = [aDecoder decodeObjectForKey:@"givenName"];
    self.familyName = [aDecoder decodeObjectForKey:@"familyName"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];

    if (nil != self.givenName) {
        [aCoder encodeObject:self.givenName forKey:@"givenName"];
    }

    if (nil != self.familyName) {
        [aCoder encodeObject:self.familyName forKey:@"familyName"];
    }
}

- (BOOL)hasName
{
    return !(nil == self.familyName || [@"" isEqualToString:self.familyName] || nil == self.givenName || [@"" isEqualToString:self.givenName]);
}

@end
