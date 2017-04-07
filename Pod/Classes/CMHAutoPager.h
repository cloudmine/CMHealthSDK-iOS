#import <Foundation/Foundation.h>

@class CMUser;
@class CMHInternalProfile;
@class CMObject;

typedef void(^CMHAllUsersCompletion)(NSArray<CMUser *> * _Nonnull users, NSArray<NSError *> * _Nonnull errors);
typedef void(^CMHAllProfilesCompletion)(NSArray<CMHInternalProfile *> * _Nonnull profiles, NSError * _Nullable error);
typedef void(^CMHFetchObjectsCompletion)(NSArray<CMObject *> *_Nonnull objects, NSError * _Nullable error);

@interface CMHAutoPager : NSObject

+ (void)fetchAllUsersWithCompletion:(nonnull CMHAllUsersCompletion)block;
+ (void)fetchAllUserProfilesWithCompletion:(nonnull CMHAllProfilesCompletion)block;
+ (void)fetchObjectsWithOwningUser:(nonnull NSString *)owningUserIdentifier updatedAfter:(nonnull NSString *)updateAfterStamp withCompletion:(nonnull CMHFetchObjectsCompletion)block;

@end
