#import "CMHUserData.h"
#import "CMHUserData_internal.h"

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


@end
