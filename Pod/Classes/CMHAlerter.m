#import "CMHAlerter.h"

@implementation CMHAlerter

+ (void)displayAlertWithTitle:(NSString *_Nullable)title
                   andMessage:(NSString *_Nonnull)message
             inViewController:(UIViewController *_Nonnull)viewController
{
    NSAssert(nil != message, @"ACMAlertFactory: Attempted to display an alert with nil message");
    NSAssert(nil != viewController, @"ACMAlertFactory: Attempted to display an alert in a nil view controller");

    if ([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue]) {
        [self _displayAlertWithTitle:title andMessage:message inViewController:viewController];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _displayAlertWithTitle:title andMessage:message inViewController:viewController];
        });
    }
}

#pragma mark Private

+ (void)_displayAlertWithTitle:(NSString *_Nullable)title
                   andMessage:(NSString *_Nonnull)message
             inViewController:(UIViewController *_Nonnull)viewController
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { }];
    [alert addAction:okAction];

    [viewController presentViewController:alert animated:YES completion:nil];
}

@end
