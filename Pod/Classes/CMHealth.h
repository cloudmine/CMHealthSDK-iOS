#import <ResearchKit/ResearchKit.h>

#import "CMHErrors.h"
#import "CMHUserData.h"
#import "CMHConsent.h"
#import "CMHUser.h"
#import "ORKResult+CMHealth.h"
#import "ORKConsentSection+CMHealth.h"
#import "CMHAuthViewController.h"

@interface CMHealth : NSObject

+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret;

@end