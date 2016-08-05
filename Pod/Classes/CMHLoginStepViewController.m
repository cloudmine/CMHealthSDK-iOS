#import "CMHLoginStepViewController.h"
#import "CMHInputValidators.h"
#import "CMHAlerter.h"
#import "CMHUser.h"

@interface CMHLoginStepViewController ()

@end

@implementation CMHLoginStepViewController

- (void)forgotPasswordButtonTapped
{
    UIAlertController *resetAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Reset Password", nil)
                                                                        message:NSLocalizedString(@"Please enter the email address you used to create your account", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];

    [resetAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Email", nil);
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }];

    [resetAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                   style:UIAlertActionStyleCancel
                                                 handler:^(UIAlertAction * _Nonnull action) { }]];

    UIAlertAction *resetAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Reset", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *email = resetAlert.textFields[0].text;
        [self resetPasswordForAccountWithEmail:email];
    }];
    [resetAlert addAction:resetAction];

    [self presentViewController:resetAlert animated:YES completion:nil];
}

- (void)resetPasswordForAccountWithEmail:(NSString *_Nullable)email
{
    NSString *invalidEmailMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:email];
    if (nil != invalidEmailMessage) {
        [CMHAlerter displayAlertWithTitle:NSLocalizedString(@"", nil) andMessage:invalidEmailMessage inViewController:self];
        return;
    }

    [[CMHUser currentUser] resetPasswordForAccountWithEmail:email withCompletion:^(NSError * _Nullable error) {
        if (nil != error) {
            [CMHAlerter displayAlertWithTitle:NSLocalizedString(@"Password Reset Failed", nil)
                                   andMessage:error.localizedDescription
                             inViewController:self];
            return;
        }

        [CMHAlerter displayAlertWithTitle:NSLocalizedString(@"Password Reset", nil)
                               andMessage:NSLocalizedString(@"An email with instructions for reseting your password has been sent", nil)
                         inViewController:self];
    }];
}

@end
