#import <CloudMine/CloudMine.h>

@interface CMHInternalProfile : CMObject

@property (nonatomic, copy, nullable) NSString *email;
@property (nonatomic) BOOL isAdmin;
@property (nonatomic, copy, nullable) NSString *givenName;
@property (nonatomic, copy, nullable) NSString *familyName;
@property (nonatomic, copy, nullable) NSString *gender;
@property (nonatomic, copy, nullable) NSDate *dateOfBirth;
@property (nonatomic, copy, nullable) NSString *cmhOwnerId;
@property (nonatomic, copy, nullable) NSString *photoId;
@property (nonatomic, copy, nonnull) NSDictionary<NSString *, id<NSCoding>> *userInfo;

@end
