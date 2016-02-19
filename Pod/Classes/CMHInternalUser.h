#import <CloudMine/CloudMine.h>

@interface CMHInternalUser : CMUser

@property (nonatomic) NSString *givenName;
@property (nonatomic) NSString *familyName;
@property (nonatomic, readonly) BOOL hasName;

@end
