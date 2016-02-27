# CMHealth

CMHealth is the easiest way to add secure, HIPAA compliant cloud data storage
and user management to your [ResearchKit](http://researchkit.org/) clinical study
iOS app.  Built and backed by [CloudMine](http://cloudmineinc.com/) and the
CloudMine Connected Health Cloud.

**IMPORTANT NOTICE**: This SDK is pre-1.0 software. It is very likely there will
be breaking changes to the API and data schema before a stable release. Your
feedback is welcomed in this process. Please feel free to open an issue or
pull request.


## Installation

CMHealth is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "CMHealth"
```

## Usage

The SDK provides category methods on standard ResearchKit classes, allowing you to save
and fetch results with ease.

### Save
```Objective-C
#import <CMHealth/CMHealth.h>

// `surveyResult` is an instance of ORKTaskResult, or any ORKResult subclass
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

### Authentication
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

The SDK also provides [preconfigured screens](#authentication-screens)
for participant authentication.

### Consent

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

### Authentication Screens

For convenience, the SDK provides preconfigured view controllers for user sign up and login.
These screens can be presented modally and handle the collection and validation of user
email and password. Data is returned via delegation.

![Login Screenshot](./CMHealth-SDK-Login-Screen.png)

```Objective-C
#import "MyViewController.h"
#import <CMHealth/CMHealth.h>

@interface MyViewController () <CMHAuthViewDelegate>
@end

@implementation MyViewController
- (IBAction)loginButtonDidPress:(UIButton *)sender
{
    CMHAuthViewController *loginViewController = [CMHAuthViewController loginViewController];
    loginViewController.delegate = self;
    [self presentViewController:loginViewController animated:YES completion:nil];
}

#pragma mark CMHAuthViewDelegate

- (void)authViewCancelledType:(CMHAuthType)authType
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)authViewOfType:(CMHAuthType)authType didSubmitWithEmail:(NSString *)email andPassword:(NSString *)password
{
    [self dismissViewControllerAnimated:YES completion:nil];

    switch (authType) {
        case CMHAuthTypeLogin:
            [self loginWithEmail:email andPassword:password];
            break;
        case CMHAuthTypeSignup:
            [self signupWithEmail:email andPassword:password];
            break;
        default:
            break;
    }
}

#pragma mark Private

- (void)signupWithEmail:(NSString *)email andPassword:(NSString *)password
{
    // Sign user up
}

- (void)loginWithEmail:(NSString *)email andPassword:(NSString *a)password
{
    // Log user in
}

@end
```

### The Rest of CloudMine

CMHealth includes and extends the [CloudMine iOS SDK](https://cocoapods.org/pods/CloudMine), so you
get all of the core CloudMine functionality for free.  To go beyond the ResearchKit specific parts
of CMHealth, start with the [CloudMine iOS documentation](https://cloudmine.io/docs/#/ios).


## CMHealth in Action

To get a sense of how CMHealth works seamlessly with ResearchKit, you can check out the CloudMine
[AsthmaHealth](https://github.com/cloudmine/AsthmaHealth/) demo application.  AsthmaHealth
can also serve as a starting point for your own ResearchKit enabled app.


## Support

For general CMHealth support, please email support@cloudmine.me - we are here to help!

For the more advantageous, we encourage getting directly involved via standard GitHub
fork, issue tracker, and pull request pathways.  See the [CONTRIBUTING](CONTRIBUTING.md)
document to get started.


## License

CMHealth is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

