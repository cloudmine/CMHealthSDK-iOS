#import "CMHInternalProfile.h"
#import "CMHConstants_internal.h"

@implementation CMHInternalProfile

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    _email = [aDecoder decodeObjectForKey:@"email"];
    _isAdmin = [aDecoder decodeBoolForKey:@"isAdmin"];
    _givenName = [aDecoder decodeObjectForKey:@"givenName"];
    _familyName = [aDecoder decodeObjectForKey:@"familyName"];
    _gender = [aDecoder decodeObjectForKey:@"gender"];
    _dateOfBirth = [aDecoder decodeObjectForKey:@"dateOfBirth"];
    _cmhOwnerId = [aDecoder decodeObjectForKey:CMHOwningUserKey];
    _userInfo = [aDecoder decodeObjectForKey:@"userInfo"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.email forKey:@"email"];
    [aCoder encodeBool:self.isAdmin forKey:@"isAdmin"];
    [aCoder encodeObject:self.cmhOwnerId forKey:CMHOwningUserKey];
    [aCoder encodeObject:self.givenName forKey:@"givenName"];
    [aCoder encodeObject:self.familyName forKey:@"familyName"];
    [aCoder encodeObject:self.gender forKey:@"gender"];
    [aCoder encodeObject:self.dateOfBirth forKey:@"dateOfBirth"];
    [aCoder encodeObject:self.userInfo forKey:@"userInfo"];
}

- (NSDictionary<NSString *,id<NSCoding>> *)userInfo
{
    if (nil == _userInfo) {
        _userInfo = @{};
    }
    
    return _userInfo;
}

@end
