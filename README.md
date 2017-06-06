# CMHealth

[CMHealth](https://cocoapods.org/pods/CMHealth) is the easiest way to add secure, HIPAA compliant cloud data storage
and user management to your [ResearchKit](http://researchkit.org/) or [CareKit](http://carekit.org/)
iOS app.  Built and backed by [CloudMine](http://cloudmineinc.com/) and the
CloudMine [Connected Health Cloud](http://cloudmineinc.com/platform/developer-tools/).

## Installation

[CMHealth](https://cocoapods.org/pods/CMHealth) is available through [CocoaPods](http://cocoapods.org) version 1.0.0 or later.
To install it, simply add the following line to your Podfile:

```ruby
platform :ios, '9.0'

target 'MyHealthApp' do
  use_frameworks!

  pod 'CMHealth'
end
```

Once intalled, the SDK must be imported and configured in your `AppDelegate` class. See the section on
[Configuration](#configuration) for more information.

## ResearchKit

The SDK provides category methods on standard ResearchKit classes, allowing you
to save and fetch `ORKTaskResult` objects to and from the [CloudMine Connected Health Cloud](http://cloudmineinc.com/platform/developer-tools/).

You can see the full documentation and class references on [CocoaPods](http://cocoadocs.org/docsets/CMHealth/)
or [GitHub](https://github.com/cloudmine/CMHealthSDK-iOS/tree/master/docs).

#### Save

```Objective-C
#import <CMHealth/CMHealth.h>

// surveyResult is an instance of ORKTaskResult, or any ORKResult subclass
[surveyResult cmh_saveToStudyWithDescriptor:@"MyClinicalStudy" withCompletion:^(NSString *uploadStatus, NSError *error) {
        if (nil == uploadStatus) {
            // handle error
            return;
        }
        if ([uploadStatus isEqualToString:@"created"]) {
            // A new research kit result was saved
        } else if ([uploadStatus isEqualToString:@"updated"]) {
            // An existing research kit result was updated
        }
    }];
```

#### Fetch

```Objective-C
#import <CMHealth/CMHealth.h>

[ORKTaskResult cmh_fetchUserResultsForStudyWithDescriptor:@"MyClinicalStudy" withCompletion:^(NSArray *results, NSError *error) {
        if (nil == results) {
            // handle error
            return;
        }

        for (ORKTaskResult *result in results) {
            // use your result
        }
    }];
```

## CareKit

The SDK provides the ability to synchronize data between your
CareKit app's local device store and  the 
[CloudMine Connected Health Cloud](http://cloudmineinc.com/platform/developer-tools/).

### Overview

CloudMine's platform offers a robust [`Snippet`](https://cloudmine.io/docs/#/server_code#logic-engine) and [`ACL`](https://cloudmine.io/docs/#/rest_api#user-data-security) framework, which are dependencies of the CMHealth framework when using CareKit. The CareKit SDK will automatically store `OCKCarePlanActivity` and `OCKCarePlanEvent` objects in the logged-in user-level data store. In order to grant a CareProvider access to this data, the `ACL` framework and a server-side `Logic Engine Snippet` is required to properly attach the appropriate `acl_id`. 

### Configuration 

The below steps are pre-requisites to using the CareKit framework with CloudMine. For assistance with this one-time configuration on CloudMine's platform, please contact [support@cloudmineinc.com](mailto:support@cloudmineinc.com).

#### Enable Automatic Timestamping 

The automatic timestamping (`auto_ts`) feature must be enabled for your `app_id`. This feature can be enabled by running the following `cURL` request:

```
some example
```

*Note: the `Master API Key` is required in order to execute this cURL. It is strongly recommended to cycle the Master API Key or to ensure that it is safeguarded when being used client side to prevent unauthorized access to your application's data.*

Once `auto_ts` is enabled, all application and user-level objects will automatically be updated with `__updated__` and `__created__` key-value pairs, which will automatically be maintained by the CloudMine platform. 

#### Create the Admin User and ACL

```
some examples here
```

#### Develop and Upload the Administrative Snippet

```
some examples here
```

#### Update `BCMSecrets.h` and configure the `AppDelegate`

```
some example here
```

Finally, the configuration in your
`AppDelegate` is simple:

```Objective-C
#import <CMHealth/CMHealth.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [CMHealth setAppIdentifier:@"My-CloudMine-App-ID" appSecret:@"My-CloudMine-API-Key" sharedUpdateSnippetName:@"My-Deployed-Shared-Snippet-Name"];
	return YES;
}
```
Congrats! You are now ready to begin building your application using the `CMHealth` SDK and CloudMine. 

### Patient Context 

Your patient-facing app can be built using all native CareKit components with very little 
deviation from a standard CareKit app. 

#### TODO: Creating a patient? 

Maybe something goes here? 

#### Creating the `CMHCarePlanStore`

Simply replace the `OCKCarePlanStore` with an 
instance of our custom subclass, `CMHCarePlanStore`, and your user's data will be 
automatically pushed to CloudMine.

```Objective-C
#import <CMHealth/CMHealth.>

// `self.carePlanStore` is assumed to be a @property of type CMHCarePlanStore
self.carePlanStore = [CMHCarePlanStore storeWithPersistenceDirectoryURL:BCMStoreUtils.persistenceDirectory];
self.carePlanStore.delegate = self;
```

As long as your patient user is logged in and your CloudMine account is properly configured,
your CareKit app will now automatically push changes made in the local store up to
the cloud.

#### Creating a New Activity 

For example, adding a new activity to the store will result in a representation of that activity
being pushed to CloudMine's backend for the current user.

```Objective-C
#import <CMHealth/CMHealth.h>

// Create a standard OCKCarePlanActivity instance somewhere in your app
OCKCarePlanActivity *activity = [self activityGenerator];

// Add this activity to the store as you would in a standard CareKit app
[self.carePlanStore addActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
    if (!success) {
		NSLog(@"Failed to add activity to store: %@", error.localizedDescription);
		return;
    }
    
    NSLog(@"Activity added to store");
}];
```

Note the above code is no different from what you would write for a standard, local-only, CareKit app.
No additional consideration is required to push `CMHCarePlanStore` entries to CloudMine!

#### Fetching Updates from CloudMine for the local `CMHCarePlanStore`

Fetching updates _from_ the cloud is similiarly simple. A single method allows you to synchronize the local store 
with all data that has been added remotely since the last time it was called successfully.

```Objective-C
#import <CMHealth/CMHealth.h>

[self.carePlanStore syncFromRemoteWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
    if (!success) {
        NSLog(@"Error(s) syncing remote data %@", errors);
        return;
    }
        
    NSLog(@"Successful sync of remote data");
 }];
```

This allows your app to sync across devices and sessions with minimal effort.

### Provider Context

To help organizations access the patient-generated data, the `CMHealth` SDK allows for fetching an aggregated view of all patients and their activity/event data based on the `ACL` we created in the configuration section. 

#### Fetching All Patients

To fetch a list of `OCKPatient` instances for use within your application, call the
`fetchAllPatientsWithCompletion:` class method on `CMHCarePlanStore`.

```Objective-C
[CMHCarePlanStore fetchAllPatientsWithCompletion:^(BOOL success, NSArray<OCKPatient *> * _Nonnull patients, NSArray<NSError *> * _Nonnull errors) {
	if (!success) {
        NSLog(@"Errorse fetching patients: %@", errors);
        return;
	}
        
    self.patients = patients;
}];

```

Subsequent calls to this class method will return a list of updated patients, but will
intelligently sync _only_ data added or updated since the
last time it was called.

*TODO: Any changes made to the patient's data using the Care Team Dashboard 
will be automatically pushed to CloudMine's backend.*

#### Adding New Administrative Users

```
some stuff here
```

## Registration

The SDK provides a user abstraction for managing your participant accounts, with straightforward
methods for user authentication.

```Objective-C
#import <CMHealth/CMHealth.h>

[[CMHUser currentUser] signUpWithEmail:email password:password andCompletion:^(NSError *error) {
    if (nil != error) {
        // handle error
        return;
    }

    // The user is now signed up
}];
```

The SDK also provides a convenient way to complete user signup if your app uses a standard
ResearchKit `ORKRegistrationStep`. Simply pass the `ORKTaskResult`
to the `signupWithRegistration:andCompletion:` method. The SDK ensures
a registration result is present in the results hierarchy and extracts the relevant
participant data before registering the user's account.

```Objective-C
#import <CMHealth/CMHealth.h>

#pragma mark ORKTaskViewControllerDelegate

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(NSError *)error
{
    if (nil != error) {
        // Handle Error
        return;
    }

    if (reason == ORKTaskViewControllerFinishReasonCompleted) {
        [CMHUser.currentUser signUpWithRegistration:taskViewController.result andCompletion:^(NSError * _Nullable signupError) {
            if (nil == signupError) {
                // Handle Error
                return;
            }

            // The user is now signed up
        }];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}
```

The SDK includes a preconfigured ResearchKit `ORKLoginStepViewController` sublcass
to handle login and password reset for existing users. The view controller can simply
be instantiated and presented; the result is returned via a delegate callback.

```Objective-C
#import <CMHealth/CMHealth.h>

- (IBAction)loginButtonDidPress:(UIButton *)sender
{
    CMHLoginViewController *loginVC = [[CMHLoginViewController alloc] initWithTitle:NSLocalizedString(@"Log In", nil)
                                                                               text:NSLocalizedString(@"Please log in to you account to store and access your research data.", nil)
                                                                           delegate:self];
    loginVC.view.tintColor = [UIColor greenColor];

    [self presentViewController:loginVC animated:YES completion:nil];
}

#pragma mark CMHLoginViewControllerDelegate

- (void)loginViewControllerCancelled:(CMHLoginViewController *)viewController
{
    // User cancelled login process
}

- (void)loginViewController:(CMHLoginViewController *)viewController didLogin:(BOOL)success error:(NSError *)error
{
    if (!success) {
        // Handle Error
        return;
    }

    // The user is now logged in
}
```

## Consent

The SDK provides specific methods for archiving and fetching participant consent.
In ResearchKit, user consent is collected in any `ORKTask` with special consent and signature
steps included. CMHealth allows you to archive the resulting `ORKTaskResult` object
containing the user's consent. The SDK ensures that a consent step is present in the result hierarchy and that a signature has been collected. It handles uploading the signature image seamlessly.

```Objective-C
#import <CMHealth/CMHealth.h>

// `consentResults` is an instance of `ORKTaskResult`
[[CMHUser currentUser] uploadUserConsent:consentResults forStudyWithDescriptor:@"MyClinicalStudy" andCompletion:^(NSError * consentError) {
    if (nil != error) {
        // handle error
        return;
    }

    // consent uploaded successfully
}];
```

To ensure your participants have a valid consent on file before allowing them to participate in study activities, you can fetch any user's consent object.

```Objective-C
#import <CMHealth/CMHealth.h>

[[CMHUser currentUser] fetchUserConsentForStudyWithDescriptor:@"MyClinicalStudy" andCompletion:^(CMHConsent *consent, NSError *error) {
    if (nil != error) {
        // Something went wrong
        return;
    }

    if (nil == consent) {
        // No consent on file
        return;
    }

    // User has valid consent on file
}];

```

## Configuration

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

 
## Using the CloudMine iOS SDK with CMHealth

[CMHealth](https://cocoapods.org/pods/CMHealth) includes and extends the [CloudMine iOS SDK](https://cocoapods.org/pods/CloudMine), so you
get all of the core CloudMine functionality for free.  To go beyond the ResearchKit specific parts
of [CMHealth](https://cocoapods.org/pods/CMHealth), start with the [CloudMine iOS documentation](https://cloudmine.io/docs/#/ios).

## CMHealth Examples

To get a sense of how CMHealth works seamlessly with ResearchKit, you can check out the CloudMine
[AsthmaHealth](https://github.com/cloudmine/AsthmaHealth/) demo application.
The SDK is designed to work seamlessly with [Swift](https://swift.org/).
Check out the [AsthmaHealthSwift](https://github.com/cloudmine/AsthmaHealthSwift) demo to
see an all-Swift app enabled by CMHealth.

To see an example of CMHealth working in tandem with CareKit, you can check out the CloudMine
[BackTrack](TODO: URL) demo application.

## Support

For general [CMHealth](https://cocoapods.org/pods/CMHealth) support, please email support@cloudmineinc.com - we are here to help!

For the more advantageous, we encourage getting directly involved via standard GitHub
fork, issue tracker, and pull request pathways.  See the [CONTRIBUTING](CONTRIBUTING.md)
document to get started.

## License

CMHealth is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
