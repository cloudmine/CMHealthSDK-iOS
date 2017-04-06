#import <Foundation/Foundation.h>

@class CMUser;
@class CMHInternalProfile;

typedef void(^CMHAllUsersCompletion)(NSArray<CMUser *> * _Nonnull users, NSArray<NSError *> * _Nonnull errors);
typedef void(^CMHAllProfilesCompletion)(NSArray<CMHInternalProfile *> * _Nonnull profiles, NSError * _Nullable error);

@interface CMHAutoPager : NSObject

+ (void)fetchAllUsersWithCompletion:(nonnull CMHAllUsersCompletion)block;
+ (void)fetchAllUserProfilesWithCompletion:(nonnull CMHAllProfilesCompletion)block;

@end
