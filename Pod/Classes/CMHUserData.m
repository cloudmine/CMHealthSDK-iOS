#import "CMHUserData.h"
#import "CMHUserData_internal.h"
#import "CMHInternalProfile.h"

@implementation CMHUserData

- (instancetype)initWithInternalUser:(CMHInternalUser *)user
{
    self = [super init];
    if (nil == self || nil == user) return nil;

    self.email = user.email;
    self.familyName = user.familyName;
    self.givenName = user.givenName;

    return self;
}

- (_Nullable instancetype)initWIthInternalProfile:(CMHInternalProfile *_Nullable)profile
{
    self = [super init];
    if (nil == self || nil == profile) return nil;

    self.email = profile.email;
    self.givenName = profile.givenName;
    self.familyName = profile.familyName;

    return self;
}


@end
