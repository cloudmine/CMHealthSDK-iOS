#import "CMHealth.h"
#import <CloudMine/CloudMine.h>

@implementation CMHealth

+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret
{
    NSAssert(nil != identifier, @"CMHealth App Identifier can not be nil");
    NSAssert(nil != secret, @"CMHealth App Secret can not be nil");

    CMAPICredentials *credentials = [CMAPICredentials sharedInstance];
    credentials.appIdentifier = identifier;
    credentials.appSecret = secret;
}

@end