#import <Foundation/Foundation.h>

/**
 *  Immutable "bag of data" for a given user. Developers should only
 *  consume these objects from the `CMHUser` isntance.
 *
 *  @see CMHUser class
 */
@interface CMHUserData : NSObject

/**
 *  Email address used to create the account. Never `nil`.
 */
@property (nonatomic, nonnull, readonly) NSString *email;

/**
 *  Family name, if availble, or `nil`.
 */
@property (nonatomic, nullable, readonly) NSString *familyName;

/**
 *  Given name, if available, or `nil`.
 */
@property (nonatomic, nullable, readonly) NSString *givenName;

@end
