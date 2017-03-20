#import "CMHealth.h"
#import <CloudMine/CloudMine.h>
#import "CMHConfiguration.h"

@implementation CMHealth

+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret
{
    [self setAppIdentifier:identifier appSecret:secret sharedUpdateSnippetName:nil];
}

+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret sharedUpdateSnippetName:(NSString *_Nullable)snippetName;
{
    NSAssert(nil != identifier, @"CMHealth App Identifier can not be nil");
    NSAssert(nil != secret, @"CMHealth App Secret can not be nil");
    
    CMAPICredentials *credentials = [CMAPICredentials sharedInstance];
    credentials.appIdentifier = identifier;
    credentials.appSecret = secret;
    
    NSAssert(nil == snippetName || snippetName.length > 0, @"Please provide a valid Shared Object Update Snippet Name, not an empty string");
    
    [CMHConfiguration sharedConfiguration].sharedObjectUpdateSnippetName = snippetName;
}

@end
