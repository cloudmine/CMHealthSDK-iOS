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


+ (ORKConsentSection *)initCloudMineSecureConsentSection
{
    NSBundle *CMHealthBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle]
                                                         pathForResource:@"CMHealth"
                                                         ofType:@"bundle"]];
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[CMHealthBundle bundlePath] error:nil];
    NSLog(@"XXXXXXXXXXXXXX local bundle: %@", files);
    
    NSArray *mfiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSBundle mainBundle] bundlePath] error:nil];
    NSLog(@"XXXXXXXXXXXXXX main bundle: %@", mfiles);
    
    ORKConsentSection *section = [[ORKConsentSection alloc] initWithType:ORKConsentSectionTypeCustom];
    
    section.title = [CMHealthBundle localizedStringForKey:@"CMHSecureConsentSectionTitle" value:nil table:nil];
    
    // after cocoapods 1.0 is released use this.  don't forget to update the CMHealth.podspec
    //section.customImage = [UIImage imageNamed:@"CloudMineLogo" inBundle:CMHealthBundle compatibleWithTraitCollection:nil];
    section.customImage = [UIImage imageNamed:@"CloudMineLogo"];
    NSLog(@"XXXXXXXXXXXXXX image from bundle: %@", [section.customImage description]);
    
    section.summary = [CMHealthBundle localizedStringForKey:@"CMHSecureConsentSectionSummary" value:nil table:nil];
    
    section.content = [CMHealthBundle localizedStringForKey:@"CMHSecureConsentSectionContent" value:nil table:nil];
    
    return section;
}

@end