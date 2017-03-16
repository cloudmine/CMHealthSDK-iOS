#import <Foundation/Foundation.h>
#import "CMHUserData.h"

@interface CMHMutableUserData : CMHUserData

@property (nonatomic, nullable, readwrite) NSString *familyName;
@property (nonatomic, nullable, readwrite) NSString *givenName;
@property (nonatomic, nullable, readwrite) NSString *gender;
@property (nonatomic, nullable, readwrite) NSDate *dateOfBirth;

@end
