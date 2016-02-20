#import "CMHealth.h"

@implementation CMHealth

+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret
{
    NSAssert(nil != identifier, @"CMHealth App Identifier can not be nil");
    NSAssert(nil != secret, @"CMHealth App Secret can not be nil");

    CMAPICredentials *credentials = [CMAPICredentials sharedInstance];
    credentials.appIdentifier = identifier;
    credentials.appSecret = secret;
}


+ (ORKConsentSection *_Nonnull)initCloudMineSecureConsentSection
{
    SETUP_CMHEALTH_BUNDLE
    
    ORKConsentSection *section = [[ORKConsentSection alloc] initWithType:ORKConsentSectionTypeCustom];
    
    section.title = [CMHealthBundle localizedStringForKey:@"CMHSecureConsentSectionTitle" value:nil table:nil];
    
    section.summary = [CMHealthBundle localizedStringForKey:@"CMHSecureConsentSectionSummary" value:nil table:nil];
    
    section.content = [CMHealthBundle localizedStringForKey:@"CMHSecureConsentSectionContent" value:nil table:nil];
    
    // after cocoapods 1.0 is released we can use Assets.xcasetts for images, etc.
    // don't forget to update the CMHealth.podspec
    section.customImage = [[UIImage imageNamed:@"cloudmine-logo.png" inBundle:CMHealthBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    return section;
}

@end