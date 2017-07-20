#import <ResearchKit/ResearchKit.h>
#import <CareKit/CareKit.h>

#import "CMHErrors.h"
#import "CMHUserData.h"
#import "CMHMutableUserData.h"
#import "CMHConsent.h"
#import "CMHUser.h"
#import "ORKResult+CMHealth.h"
#import "ORKConsentSection+CMHealth.h"
#import "CMHLoginViewController.h"
#import "CMHCarePlanStore.h"
#import "CMHCareSyncBlocks.h"
#import "OCKPatient+CMHealth.h"

/**
 *  CMHealth is the easiest way to add secure, HIPAA compliant cloud data storage and user
 *  management to your ResearchKit or CareKit clinical iOS app. Built and backed by CloudMine
 *  and the CloudMine Connected Health Cloud.
 *
 *  @see https://github.com/cloudmine/CMHealthSDK-iOS
 */
@interface CMHealth : NSObject

/**
 *  Configures global state needed to establish communication with the CloudMine backend.
 *  Typically, this would be invoked in the `-application:didFinishLaunchingWithOptions:`
 *  method of your app delegate class. Use this method if your app needs to save
 *  and fetch ResearchKit objects but does not utilize CareKit.
 *
 *  @param identifier The identifier for this app on the CloudMine backend
 *  @param secret Your app secret, also referred to as an API Key
 */
+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret;

/**
 *  Configure global state needed to establish communication with the CloudMine backend and
 *  to properly save and fetch shared CareKit objects. Typically, this method would be invoked in
 *  the `-application:didFinishLaunchWithOptions:` method. Use this method if you are building
 *  a syncing CareKit app.
 * 
 *  @param identifier The identifier for this app on the CloudMine backend
 *  @param secret Your app secret, also referred to as an API Key
 *  @param snippetName The name of the serverside snippet that applies the correct ACL permissions
 *  to shared CareKit objects when saved. This snippet is assumed by the framework to apply a shared
 *  ACL to all CareKit objects that will allow them to be accessed by the saving user and
 *  admin users, that is, Care Providers.
 *
 *  @warning The behavior of the snippet provided in this method is assumed by the framework and
 *  is not arbitrary. For help configuring and deploying the correct snippet, contact 
 *  support@cloudmineinc.com
 */
+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret sharedUpdateSnippetName:(NSString *_Nullable)snippetName;

@end
