#import "CMHUserData.h"
#import "CMHInternalUser.h"

@class CMHInternalProfile;

#ifndef CMHUserData_internal_h
#define CMHUserData_internal_h

@interface CMHUserData ()
- (_Nullable instancetype)initWithInternalProfile:(CMHInternalProfile *_Nullable)profile;
@end

#endif
