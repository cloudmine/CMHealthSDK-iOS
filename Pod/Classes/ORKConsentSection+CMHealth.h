#import <ResearchKit/ResearchKit.h>

/**
 *  This category adds a class factory method for generating a preconfigured section
 *  that informs the user their data will be stored securely by CloudMine. It is
 *  suitable for inclusion in a study consent flow.
 *
 *  @see +cmh_sectionForSecureCloudMineDataStorage
 */
@interface ORKConsentSection (CMHealth)

/**
 * Returns a preconfigured section that informs the user their data will be stored 
 * securely by CloudMine. It is suitable for inclusion in a study consent flow.
 */
+ (ORKConsentSection *_Nonnull)cmh_sectionForSecureCloudMineDataStorage;

@end