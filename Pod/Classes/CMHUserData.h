#import <Foundation/Foundation.h>

@interface CMHUserData : NSObject

@property (nonatomic, nonnull, readonly) NSString *email;
@property (nonatomic, nullable, readonly) NSString *familyName;
@property (nonatomic, nullable, readonly) NSString *givenName;

@end
