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

The SDK provides the ability to save and fetch data stored in
CareKit's local device store to and from the [CloudMine Connected Health Cloud](http://cloudmineinc.com/platform/developer-tools/).

#### Activities

Patients using a CareKit app are assigned activities to perform according to a pre-determined
schedule. These activities can be easily pushed to or fetched from CloudMine.

```Objective-C
#import <CMHealth/CMHealth.h>

// SAVE

- (void)addInitialActivities
{
    // Add activities to local stores store

    [self.carePlanStore cmh_saveActivtiesWithCompletion:^(NSString * _Nullable uploadStatus, NSError * _Nullable error) {
        if (nil == uploadStatus) {
            // Handle Error
            return;
        }

        // All activities in store saved remotely
    }];
}

// FETCH

- (void)fetchAndLoadActivities
{
    [self.carePlanStore cmh_fetchActivitiesWithCompletion:^(NSArray<OCKCarePlanActivity *> * _Nonnull activities, NSError * _Nullable error) {
        if (nil != error) {
            // handle error
        }

        // Sucessfully fetched activity

        for (OCKCarePlanActivity *activity in activities) {
            [self.carePlanStore addActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
                if (!success) {
                    // handle error
                    return;
                }

                // activity added successfully
            }];
        }
    }];
}
```

#### Events

As patients complete their activities CareKit creates events recording the data generated.
CMHealth makes it simple to save these events or to fetch and load them into the local store,
enabling you to collect important patient data across logins and devices.

```Objective-C
#import <CMHealth/CMHealth.h>

// SAVE

#pragma mark OCKCarePlanStoreDelegate
- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event
{
    [event cmh_saveWithCompletion:^(NSString * _Nullable uploadStatus, NSError * _Nullable error) {
        if (nil == uploadStatus) {
            // Handle Error
            return;
        }

        // Successfully saved
    }];
}

// FETCH

- (void)fetchAndLoadSavedEvents
{
    [self.carePlanStore cmh_fetchAndLoadAllEventsWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
        if (!success) {
            // Handle Error
            return;
        }

        // All events fetched and loaded to local store
    }];
}
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

For general [CMHealth](https://cocoapods.org/pods/CMHealth) support, please email support@cloudmine.me - we are here to help!

For the more advantageous, we encourage getting directly involved via standard GitHub
fork, issue tracker, and pull request pathways.  See the [CONTRIBUTING](CONTRIBUTING.md)
document to get started.

## License

CMHealth is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
