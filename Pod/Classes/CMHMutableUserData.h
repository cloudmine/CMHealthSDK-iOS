#import <Foundation/Foundation.h>
#import "CMHUserData.h"

@interface CMHMutableUserData : CMHUserData

@property (nonatomic, nullable, copy, readwrite) NSString *familyName;
@property (nonatomic, nullable, copy, readwrite) NSString *givenName;
@property (nonatomic, nullable, copy, readwrite) NSString *gender;
@property (nonatomic, nullable, copy, readwrite) NSDate *dateOfBirth;
@property (nonatomic, nonnull, copy, readwrite) NSDictionary<NSString *, id<NSCoding>> *userInfo;

@end
