#import "CMHUserData_internal.h"
#import "CMHInternalProfile.h"
#import "CMHMutableUserData.h"

@interface CMHUserData ()
@property (nonatomic, nonnull, copy, readwrite) NSString *email;
@property (nonatomic, nullable, copy, readwrite) NSString *familyName;
@property (nonatomic, nullable, copy, readwrite) NSString *givenName;
@property (nonatomic, nullable, copy, readwrite) NSString *gender;
@property (nonatomic, nullable, copy, readwrite) NSDate *dateOfBirth;
@end

@implementation CMHUserData

- (_Nullable instancetype)initWithInternalProfile:(CMHInternalProfile *_Nullable)profile
{
    self = [super init];
    if (nil == self || nil == profile) return nil;

    _email = profile.email;
    _givenName = profile.givenName;
    _familyName = profile.familyName;
    _gender = profile.gender;
    _dateOfBirth = profile.dateOfBirth;

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    CMHUserData *newUserData = [CMHUserData new];
    newUserData.email = self.email;
    newUserData.familyName = self.familyName;
    newUserData.givenName = self.givenName;
    newUserData.gender = self.gender;
    newUserData.dateOfBirth = self.dateOfBirth;
    
    return newUserData;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    CMHMutableUserData *mutableUserData = [CMHMutableUserData new];
    mutableUserData.email = self.email;
    mutableUserData.familyName = self.familyName;
    mutableUserData.givenName = self.givenName;
    mutableUserData.gender = self.gender;
    mutableUserData.dateOfBirth = self.dateOfBirth;
    
    return mutableUserData;
}


@end
