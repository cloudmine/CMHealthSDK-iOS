#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>
#import <CloudMine/CloudMine.h>

#import "CMHErrors.h"
#import "CMHUserData.h"
#import "CMHConsent.h"
#import "CMHUser.h"
#import "ORKResult+CMHealth.h"

@interface CMHealth : NSObject

+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret;

+ (ORKConsentSection *_Nonnull)initCloudMineSecureConsentSection;

@end

#define SETUP_CMHEALTH_BUNDLE \
  NSBundle *CMHealthBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"CMHealth" ofType:@"bundle"]];