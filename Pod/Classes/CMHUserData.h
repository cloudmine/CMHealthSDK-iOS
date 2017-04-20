#import <Foundation/Foundation.h>

/**
 *  Immutable "bag of data" for a given user. Developers should only
 *  consume these objects from the `CMHUser` isntance.
 *
 *  @see CMHUser class
 */
@interface CMHUserData : NSObject<NSCopying, NSMutableCopying>

/**
 *  Email address used to create the account. Never `nil`.
 */
@property (nonatomic, nonnull, readonly) NSString *email;

/**
 *  The unique identifier for this user in CloudMine.
 */
@property (nonatomic, nonnull, readonly) NSString *userId;

/**
 *  A boolean flag denoting this user as an administrator or
 *  not. In and of itself, this flag does not confer any
 *  additional capabilities to the user. In CareKit
 *  apps, any Care Provider accounts should have this property
 *  marked as `true` so they can be filtered from the set of
 *  accounts filtered from the Care Provider Dashboard.
 */
@property (nonatomic, readonly) BOOL isAdmin;

/**
 *  Family name, if available, or `nil`.
 */
@property (nonatomic, nullable, readonly) NSString *familyName;

/**
 *  Given name, if available, or `nil`.
 */
@property (nonatomic, nullable, readonly) NSString *givenName;

/**
 *  User's gender as a string, if available, or `nil`.
 */
@property (nonatomic, nullable, readonly) NSString *gender;

/**
 *  User's date of birth, if available, or `nil`.
 */
@property (nonatomic, nullable, readonly) NSDate *dateOfBirth;

/**
 * Dictionary saving any additional properties to the user's profile.
 * Use this to extend `CMHUserData` with data appropriate to your
 * domain.
 *
 * @warning Elements are restricted to JSON-COMPATIBLE TYPES ONLY
 */
@property (nonatomic, nonnull, readonly) NSDictionary<NSString *, id<NSCoding>> *userInfo;

@end
