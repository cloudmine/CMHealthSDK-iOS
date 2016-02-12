#import "CMHUserData.h"
#import "CMHInternalUser.h"

#ifndef CMHUserData_internal_h
#define CMHUserData_internal_h

@interface CMHUserData () // In an SDK this would likely go in a private/internal header file
- (_Nullable instancetype)initWithInternalUser:(CMHInternalUser *_Nullable)user;
@property (nonatomic, nonnull, readwrite) NSString *email;
@property (nonatomic, nullable, readwrite) NSString *familyName;
@property (nonatomic, nullable, readwrite) NSString *givenName;
@end

#endif
