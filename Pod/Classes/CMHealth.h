#import <ResearchKit/ResearchKit.h>
#import <CareKit/CareKit.h>

#import "CMHErrors.h"
#import "CMHUserData.h"
#import "CMHConsent.h"
#import "CMHUser.h"
#import "ORKResult+CMHealth.h"
#import "ORKConsentSection+CMHealth.h"
#import "CMHLoginViewController.h"
#import "CMHCarePlanStore.h"
#import "OCKCarePlanEvent+CMHealth.h"

/**
 *  CMHealth is the easiest way to add secure, HIPAA compliant cloud data storage and user
 *  management to your ResearchKit clinical study iOS app. Built and backed by CloudMine 
 *  and the CloudMine Connected Health Cloud.
 *
 *  @see https://github.com/cloudmine/CMHealthSDK-iOS
 */
@interface CMHealth : NSObject

/**
 *  Configures global state needed to establish communication with the CloudMine backend.
 *  Typically, this would be invoked in the `-application:didFinishLaunchingWithOptions:`
 *  method of your app delegate class.
 *
 *  @param identifier The identifier for this app on the CloudMine backend
 *  @param secret Your app secret, also referred to as an API Key
 */
+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret;

+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret sharedUpdateSnippetName:(NSString *_Nullable)snippetName;

@end
