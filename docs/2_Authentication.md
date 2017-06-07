# Authentication

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
