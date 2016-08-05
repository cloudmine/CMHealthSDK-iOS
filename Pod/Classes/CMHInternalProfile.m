#import "CMHInternalProfile.h"

@implementation CMHInternalProfile

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    self.email = [aDecoder decodeObjectForKey:@"email"];
    self.givenName = [aDecoder decodeObjectForKey:@"givenName"];
    self.familyName = [aDecoder decodeObjectForKey:@"familyName"];
    self.gender = [aDecoder decodeObjectForKey:@"gender"];
    self.dateOfBirth = [aDecoder decodeObjectForKey:@"dateOfBirth"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.email forKey:@"email"];

    if (nil != self.givenName) {
        [aCoder encodeObject:self.givenName forKey:@"givenName"];
    }

    if (nil != self.familyName) {
        [aCoder encodeObject:self.familyName forKey:@"familyName"];
    }

    if (nil != self.gender) {
        [aCoder encodeObject:self.gender forKey:@"gender"];
    }

    if (nil != self.dateOfBirth) {
        [aCoder encodeObject:self.dateOfBirth forKey:@"dateOfBirth"];
    }
}

@end
