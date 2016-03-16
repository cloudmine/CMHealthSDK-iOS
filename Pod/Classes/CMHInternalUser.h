#import <CloudMine/CloudMine.h>
#import "CMHUser.h"

@interface CMHInternalUser : CMUser

- (void)signUpWithEmail:(NSString *)email password:(NSString *)password andCompletion:(CMHUserAuthCompletion)block;

@property (nonatomic) NSString *givenName;
@property (nonatomic) NSString *familyName;
@property (nonatomic) NSString *profileId;
@property (nonatomic, readonly) BOOL hasName;

@end
