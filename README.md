<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [CMHealth](#cmhealth)
  - [Installation](#installation)
  - [Registering a User](#registering-a-user)
  - [Maintaining Consent](#maintaining-consent)
- [ResearchKit](#researchkit)
    - [Configuring your CloudMine App Secrets](#configuring-your-cloudmine-app-secrets)
    - [Save](#save)
    - [Fetch](#fetch)
- [CareKit](#carekit)
  - [Overview](#overview)
  - [Configuration](#configuration)
    - [Enable Automatic Timestamps](#enable-automatic-timestamps)
    - [Preparing the Admin User](#preparing-the-admin-user)
    - [Create the Admin Profile](#create-the-admin-profile)
    - [Reference the Admin Profile](#reference-the-admin-profile)
    - [Create the Admin `ACL`](#create-the-admin-acl)
    - [Develop and Upload the Administrative Snippet](#develop-and-upload-the-administrative-snippet)
    - [Configuring your CloudMine App Secrets](#configuring-your-cloudmine-app-secrets-1)
  - [Working with CareKit](#working-with-carekit)
    - [Creating the `CMHCarePlanStore`](#creating-the-cmhcareplanstore)
    - [Creating a New Activity](#creating-a-new-activity)
    - [Fetching Updates from CloudMine for the local `CMHCarePlanStore`](#fetching-updates-from-cloudmine-for-the-local-cmhcareplanstore)
    - [Fetching All Patients](#fetching-all-patients)
    - [Adding New Administrative Users](#adding-new-administrative-users)
- [Using the CloudMine iOS SDK with CMHealth](#using-the-cloudmine-ios-sdk-with-cmhealth)
- [CMHealth Examples](#cmhealth-examples)
- [Support](#support)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

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

## Registering a User

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

## Maintaining Consent

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


# ResearchKit

The SDK provides category methods on standard ResearchKit classes, allowing you
to save and fetch `ORKTaskResult` objects to and from the [CloudMine Connected Health Cloud](http://cloudmineinc.com/platform/developer-tools/).

You can see the full documentation and class references on [CocoaPods](http://cocoadocs.org/docsets/CMHealth/)
or [GitHub](https://github.com/cloudmine/CMHealthSDK-iOS/tree/master/docs).

### Configuring your CloudMine App Secrets

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

### Save

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

### Fetch

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

# CareKit

The `CMHealth` SDK provides the ability to synchronize data between your
CareKit app's local device store and  the 
[CloudMine Connected Health Cloud](http://cloudmineinc.com/platform/developer-tools/).

## Overview

CloudMine's platform offers a robust [`Snippet`](https://cloudmine.io/docs/#/server_code#logic-engine) and [`ACL`](https://cloudmine.io/docs/#/rest_api#user-data-security) framework, which are dependencies of the CMHealth framework when using CareKit. The CareKit SDK will automatically store `OCKCarePlanActivity` and `OCKCarePlanEvent` objects in the logged-in user-level data store. In order to grant a CareProvider access to this data, the `ACL` framework and a server-side `Logic Engine Snippet` is required to properly attach the appropriate `acl_id`. 

## Configuration 

The below steps are pre-requisites to using the CareKit framework with CloudMine. For assistance with this one-time configuration on CloudMine's platform, please contact [support@cloudmineinc.com](mailto:support@cloudmineinc.com).

### Enable Automatic Timestamps 

The automatic timestamps (`auto_ts`) feature must be enabled for your `app_id`. This feature can be enabled by running the following `cURL` request. 

Once `auto_ts` is enabled, all application and user-level objects will be updated with `__updated__` and `__created__` key-value pairs, which will automatically be maintained by the CloudMine platform. 

*Note: `auto_ts` is a cached configuration value, and it may take up to 15 minutes for the setting to take full effect.*

#### Request
```http
curl -X POST \
  https://api.cloudmine.io/admin/app/:app_id/prefs \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :master_api_key' \
  -d '{
	"auto_ts":true
}'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `master_api_key`: Required. Available within the Compass Dashboard. 

#### Response

```http
HTTP/1.1 200 OK
```
If a `4xx` error code is observed, please ensure that the `Master API Key` is being used to execute the request. 

### Preparing the Admin User

An initial administrative user is required in order to retrieve patient-level data using CloudMine's `ACL` framework. To create the administrative user, the below `cURL` may be used: 

#### Request
```http
curl -X POST \
  https://api.cloudmine.io/v1/app/:app_id/account/create \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :api_key' \
  -d '
{
    "credentials": {
        "email": "admin@example.com",
        "password": "the-password"
    },
    "profile": {
        "name": "Admin User",
        "email":"admin@example.com"
    }
}'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `api_key`: Required. Available within the Compass Dashboard.
3. `credentials.email`: Required. Refers to the administrative user's email address. 
4. `credentials.password`: Required. Sets the initial administrative password. 
5. `profile.email`: Required. Refers to the administrative user's email address. 

#### Response
```http
HTTP/1.1 201 OK
{
	"name": "Admin User",
	"email": "admin@example.com",
	"__type__": "user",
	"__id__": "54e952dd255e42ada66f04bd1d938325"
}
```

Please take note of the user `__id__` value returned -- it will be required in a future step in order to create the admin `ACL`. 

### Create the Admin Profile

In some cases, the admin profile may contain sensitive information. To account for this, the admin profile should be created as a user-level object and referenced by `__id__` on the public profile. 

#### Request
```http
curl -X POST \
  'https://api.cloudmine.io/v1/app/:app_id/user/text?userid=:admin_user_id' \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :master_api_key' \
  -d '{
    "generate-unique-profile-key": {
      "__id__": "unique-object-key",
      "cmh_owner": ":admin_user_id",
      "__access__": [
        null
      ],
      "gender": null,
      "isAdmin": true,
      "dateOfBirth": null,
      "__class__": "CMHInternalProfile",
      "email": ":admin_email",
      "familyName": null,
      "givenName": null,
      "userInfo": {
        "__class__": "map"
      },
      "__created__": "2017-06-01T15:33:46Z",
      "__updated__": "2017-06-01T15:57:43Z"
    }
  }'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `admin_user_id`: Required. Refers to the administrative user's `__id__`. 
3. `master_api_key`: Required. Available within the Compass Dashboard. 

#### Response
```http
HTTP/1.1 200 OK
{
  "success": {
    "036f5dfc5a7fdb4819c80d86429ed126": "created"
  },
  "errors": {}
}
```
Please note the value used for `generate-unique-profile-key` as it will be required in the next step. 

### Reference the Admin Profile 

Once the private profile has been created, the CareKit framework will expect to find a reference to it on the public profile. We need to update the public profile so as to ensure the profile data loads properly when the user logs in:

#### Request
```http
curl -X POST \
  'https://api.cloudmine.io/v1/app/:app_id/account/?userid=:admin_user_id' \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :master_api_key' \
  -d '{ 
  "profileId":"generate-unique-profile-key"
}'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `admin_user_id`: Required. Refers to the administrative user's `__id__`. 
3. `master_api_key`: Required. Available within the Compass Dashboard. 
4. `generate-unique-profile-key`: Required. Refers to the object key used to create the private admin profile.

#### Response
```http
HTTP/1.1 200 OK
```
Congrats! The first admin user has been successfully prepared. 

### Create the Admin `ACL`

The admin `ACL` will be used to ensure that patient data can be recalled via the administrative user. The `[members]` array is used for tracking all admin user `__id__` values, which may be added at will. Patient data will automatically be available to them once logged in. 

#### Request
```http
curl -X POST \
  'https://api.cloudmine.io/v1/app/:app_id/user/access?userid=:admin_user_id' \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :master_api_key' \
  -d '{
    "members": [":admin_user_id"],
    "permissions": ["r", "c", "u", "d"],
    "my_extra_info": "for CK admins"
}'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `master_api_key`: Required. Available within the Compass Dashboard.
3. `admin_user_id`: Required. Refers to the administrative user's `__id__`. 

#### Response
```http
HTTP/1.1 201 OK
{
  "454a72bf7ae54f73abd33d0d3690d822": {
    "__type__": "acl",
    "__id__": "454a72bf7ae54f73abd33d0d3690d822",
    "permissions": [
      "r",
      "c",
      "u",
      "d"
    ],
    "members": [
      "44629a07c9014d2eba92ae9dca1d813a"
    ],
    "segments": {}
  }
}
```

Please take note of the `__id__` value returned for the newly created `ACL`. It will be required in the next step. 

### Develop and Upload the Administrative Snippet

When an `OCKCarePlanEvent` or `OCKCarePlanActivity` object is saved, the Snippet is responsible for adding the admin `ACL` id value to the `[__access__]` field of the object, allowing for it to be shared with any CareKit admin user. An example snippet is provided here: [docs/AdministrativeSnippet/Example.js](docs/AdministrativeSnippet/Example.js).

Once completed, ensure that the Snippet is uploaded to CloudMine via the Compass dashboard. Take note of the name used to create it, as it wil be required when configuring your CloudMine app secrets in the next step.  

### Configuring your CloudMine App Secrets

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

## Working with CareKit

Your patient-facing app can be built using all native CareKit components with very little 
deviation from a standard CareKit app. 

### Creating the `CMHCarePlanStore`

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

### Creating a New Activity 

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

### Fetching Updates from CloudMine for the local `CMHCarePlanStore`

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

### Fetching All Patients

To help organizations access the patient-generated CareKit data, the `CMHealth` SDK allows for fetching an aggregated view of all patients and their activity/event data based on the `ACL` we created in the configuration section. This method requires that an admin CareKit user is signed-in. 

To fetch a list of `OCKPatient` instances for use within your application, call the
`fetchAllPatientsWithCompletion:` class method on `CMHCarePlanStore`:

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

### Adding New Administrative Users

Adding new Administrative Users requires 3 steps:

1. create the admin user
2. toggle the `isAdmin` field to `true` within the object's `CMHUserData` property,
3. add the admin `user_id` to the `[members]` field on the `acl_id` as described in the [Create the Admin `ACL`](#create-the-Admin-`ACL`) section. 

#### Creating the Admin User

The `CMUser` class contains the below method in order to create a new user within your CareKit implementation:

```Objective-C
- (void)signUpWithEmail:(NSString *_Nonnull)email
               password:(NSString *_Nonnull)password
          andCompletion:(_Nullable CMHUserAuthCompletion)block;
```
Once the user is successfully created, you are ready to move onto the next step. 

#### Creating the Admin CMHUserData Object 

The `CMHUserData` class represents additional profile data about the administrative user. In addition to representing basic details about the user, it also contains a `BOOL` property (`isAdmin`) in order to denote if the user is  indeed an admin. Once you have created an instance of `CMHUserData`, it can be attached to the target `CMHUser` using the below `CMHUser` method call:

```Objective-C
- (void)updateUserData:(CMHUserData *_Nonnull)userData
        withCompletion:(_Nullable CMHUpdateUserDataCompletion)block;
```
*Note: please ensure that the `isAdmin` boolean is set to true before calling this method, otherwise the underlying framework may not properly recognize this user as an administrator.*

#### Adding the Admin `user_id` to the Administrative ACL

After creating the user and their correpsonding profile data, the user's `__id__` value needs to be added to the admin `acl`. The below cURL request may be used as an example of how to perform this action:

##### Request
```http
curl -X POST \
  'https://api.cloudmine.io/v1/app/:app_id/user/access/:admin_acl_id?userid=:admin_user_id' \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :master_api_key' \
  -d '{
    "members": [":new_admin_id",":existing_admin_ids"]
}'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `admin_acl_id`: Required. Generated when first implementing CareKit within your App. 
3. `admin_user_id`: Required. Refers to the administrative user's `__id__`. 
4. `master_api_key`: Required. Available within the Compass Dashboard.
5. `new_admin_id`: Required. The `user_id` of the new admin to be enabled. 
6. `existing_admin_ids`: Required. Refers to existing admin users so as to ensure they are not overwritten during the insert for a net-new admin. 

##### Response
```http
HTTP/1.1 200 OK
```

*Note: it is strongly recommended that this workflow is implemented as a server-side Snippet within your larger application. Either the Master API Key or the root Admin user's password will be required in order to update the CareKit ACL. If the Master API Key is used client-side, ensure that it is handled securely or cycle the Master API Key upon completion and update the Administrative Snippet to reflect the new key.*
 
# Using the CloudMine iOS SDK with CMHealth

[CMHealth](https://cocoapods.org/pods/CMHealth) includes and extends the [CloudMine iOS SDK](https://cocoapods.org/pods/CloudMine), so you
get all of the core CloudMine functionality for free.  To go beyond the ResearchKit specific parts
of [CMHealth](https://cocoapods.org/pods/CMHealth), start with the [CloudMine iOS documentation](https://cloudmine.io/docs/#/ios).

# CMHealth Examples

To get a sense of how CMHealth works seamlessly with ResearchKit, you can check out the CloudMine
[AsthmaHealth](https://github.com/cloudmine/AsthmaHealth/) demo application.
The SDK is designed to work seamlessly with [Swift](https://swift.org/).
Check out the [AsthmaHealthSwift](https://github.com/cloudmine/AsthmaHealthSwift) demo to
see an all-Swift app enabled by CMHealth.

To see an example of CMHealth working in tandem with CareKit, you can check out the CloudMine
[BackTrack](https://github.com/cloudmine/BackTrack) demo application.

# Support

For general [CMHealth](https://cocoapods.org/pods/CMHealth) support, please email support@cloudmineinc.com - we are here to help!

For the more advantageous, we encourage getting directly involved via standard GitHub
fork, issue tracker, and pull request pathways.  See the [CONTRIBUTING](CONTRIBUTING.md)
document to get started.

# License

CMHealth is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
s