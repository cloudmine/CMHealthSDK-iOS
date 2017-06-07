# Configuring your CloudMine App Secrets

The CMHealth SDK should be [installed](#installation) via CocoaPods. The SDK should be configured in your `AppDelegate` class
to provide proper credentials to the CloudMine backend.

For ResearchKit Apps, an App Identifier and App Secret (API Key) is all that is needed:

```Objective-C
#import <CMHealth/CMHealth.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [CMHealth setAppIdentifier:@"My-CloudMine-App-ID" appSecret:@"My-CloudMine-API-Key"];	
	return YES;
}
```
