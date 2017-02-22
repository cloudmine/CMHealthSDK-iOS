#import "CMHealth.h"
#import <CloudMine/CloudMine.h>
#import "CMHConfiguration.h"

@implementation CMHealth

+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret
{
    [self setAppIdentifier:identifier appSecret:secret sharedACLId:nil];
}

+ (void)setAppIdentifier:(NSString *)identifier appSecret:(NSString *)secret sharedACLId:(NSString *_Nullable)aclId
{
    NSAssert(nil != identifier, @"CMHealth App Identifier can not be nil");
    NSAssert(nil != secret, @"CMHealth App Secret can not be nil");
    
    CMAPICredentials *credentials = [CMAPICredentials sharedInstance];
    credentials.appIdentifier = identifier;
    credentials.appSecret = secret;
    
    if (nil == aclId) {
        return;
    }
    
    NSAssert(aclId.length > 0, @"Please provide a valid Shared Object ACL Id, not an empty string");
    
    [CMHConfiguration sharedConfiguration].careObjectACLId = aclId;
}

@end
