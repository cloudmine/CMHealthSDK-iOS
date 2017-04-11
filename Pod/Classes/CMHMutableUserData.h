#import <Foundation/Foundation.h>
#import "CMHUserData.h"

/**
 * A mutable version of `CMHUserData` that enables the developer to update
 * certain propeties. These can be attained by calling `mutableCopy` on 
 * the immutable instance of `CMHUserData` exposed by `CMHUser`, and used to
 * update the user's data via the `updateUserData: withCompletion:` method.
 */
@interface CMHMutableUserData : CMHUserData

@property (nonatomic, readwrite) BOOL isAdmin;

/**
 *  Family name, if available, or `nil`.
 */
@property (nonatomic, nullable, copy, readwrite) NSString *familyName;

/**
 *  Given name, if available, or `nil`.
 */
@property (nonatomic, nullable, copy, readwrite) NSString *givenName;

/**
 *  User's gender as a string, if available, or `nil`.
 */
@property (nonatomic, nullable, copy, readwrite) NSString *gender;

/**
 *  User's date of birth, if available, or `nil`.
 */
@property (nonatomic, nullable, copy, readwrite) NSDate *dateOfBirth;

/**
 * Dictionary saving any additional properties to the user's profile.
 * Use this to extend `CMHUserData` with data appropriate to your
 * domain.
 *
 * @warning Elements are restricted to JSON-COMPATIBLE TYPES ONLY
 */
@property (nonatomic, nonnull, copy, readwrite) NSDictionary<NSString *, id<NSCoding>> *userInfo;

@end
