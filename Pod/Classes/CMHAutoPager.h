#import <Foundation/Foundation.h>

@class CMUser;

typedef void(^CMHAllUserCompletion)(NSArray<CMUser *> * _Nonnull users, NSArray<NSError *> * _Nonnull errors);

@interface CMHAutoPager : NSObject

+ (void)fetchAllUsersWithCompletion:(nonnull CMHAllUserCompletion)block;

@end
