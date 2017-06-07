# Configuring your CloudMine App Secrets

Finally, the configuration in your
`AppDelegate` is simple. Simply provide the CloudMine `app_id`, `api_key` and `shared_snippet_name` from the previous step CK objects will be synching in no time:

```Objective-C
#import <CMHealth/CMHealth.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [CMHealth setAppIdentifier:@"My-CloudMine-App-ID" appSecret:@"My-CloudMine-API-Key" sharedUpdateSnippetName:@"My-Deployed-Shared-Snippet-Name"];
	return YES;
}
```
Congrats! You are now ready to begin building your application using the `CMHealth` SDK and CloudMine. 

*Note: the `Master API Key` is required in order to execute many of the above cURLs. It is strongly recommended to cycle the Master API Key after completing configuration or to ensure that it is safeguarded when used client side to prevent unauthorized access to your application's data.*