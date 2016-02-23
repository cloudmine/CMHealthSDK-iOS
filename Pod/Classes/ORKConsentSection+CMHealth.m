#import "ORKConsentSection+CMHealth.h"
#import "CMHBundler.h"

@implementation ORKConsentSection (CMHealth)

+ (ORKConsentSection *_Nonnull)cmh_sectionForSecureCloudMineDataStorage
{
    ORKConsentSection *section = [[ORKConsentSection alloc] initWithType:ORKConsentSectionTypeCustom];
    section.title   = [[CMHBundler instance].bundle localizedStringForKey:@"CMHSecureConsentSectionTitle" value:nil table:nil];
    section.summary = [[CMHBundler instance].bundle localizedStringForKey:@"CMHSecureConsentSectionSummary" value:nil table:nil];
    section.content = [[CMHBundler instance].bundle localizedStringForKey:@"CMHSecureConsentSectionContent" value:nil table:nil];

    // after cocoapods 1.0 is released we can use Assets.xcasetts for images, etc.
    // don't forget to update the CMHealth.podspec
    section.customImage = [[UIImage imageNamed:@"cloudmine-logo.png" inBundle:[CMHBundler instance].bundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    return section;
}


@end
