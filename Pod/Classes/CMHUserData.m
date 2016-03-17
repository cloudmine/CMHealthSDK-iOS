#import "CMHUserData.h"
#import "CMHUserData_internal.h"
#import "CMHInternalProfile.h"

@implementation CMHUserData

- (_Nullable instancetype)initWithInternalProfile:(CMHInternalProfile *_Nullable)profile
{
    self = [super init];
    if (nil == self || nil == profile) return nil;

    self.email = profile.email;
    self.givenName = profile.givenName;
    self.familyName = profile.familyName;

    return self;
}


@end
