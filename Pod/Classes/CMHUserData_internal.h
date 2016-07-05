#import "CMHUserData.h"
#import "CMHInternalUser.h"

@class CMHInternalProfile;

#ifndef CMHUserData_internal_h
#define CMHUserData_internal_h

@interface CMHUserData ()
- (_Nullable instancetype)initWithInternalProfile:(CMHInternalProfile *_Nullable)profile;
@property (nonatomic, nonnull, readwrite) NSString *email;
@property (nonatomic, nullable, readwrite) NSString *familyName;
@property (nonatomic, nullable, readwrite) NSString *givenName;
@property (nonatomic, nullable, readwrite) NSString *gender;
@property (nonatomic, nullable, readwrite) NSDate *dateOfBirth;
@end

#endif
