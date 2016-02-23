#import "CMHSignupViewController.h"
#import "CMHBundler.h"
#import "CMHInputValidators.h"
#import "CMHAlerter.h"

@interface CMHSignupViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@end

@implementation CMHSignupViewController

#pragma mark Factory Instantiation

+ (_Nonnull instancetype)signupViewController
{
    UIViewController *vc = [[UIStoryboard storyboardWithName:@"CMHSignup" bundle:[CMHBundler instance].bundle] instantiateInitialViewController];
    NSAssert(nil != vc, @"Failed to load CMHSignupViewController from Storyboard");
    NSAssert([vc isKindOfClass:[self class]], @"Expected to load %@ but got %@", [self class], [vc class]);
    return (CMHSignupViewController *)vc;
}

#pragma mark Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.nextButton.enabled = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextChange) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Target-Action

- (IBAction)nextButtonDidPress:(UIBarButtonItem *)sender
{
    NSString *invalidEmailMessage = [CMHInputValidators localizedValidationErrorMessageForEmail:self.emailTextField.text];

    if (nil != invalidEmailMessage) {
        [CMHAlerter displayAlertWithTitle:nil andMessage:invalidEmailMessage inViewController:self];
        return;
    }

    [self.delegate signupViewDidCompleteWithEmail:self.emailTextField.text andPassword:self.passwordTextField.text];
}

- (IBAction)cancelButtonDidPress:(UIBarButtonItem *)sender
{
    [self.delegate signupViewDidCancel];
}

#pragma mark Notifications

- (void)handleTextChange
{
    self.nextButton.enabled = self.hasEnteredInputs;
}

#pragma mark Private Helpers

- (BOOL)hasEnteredInputs
{
    return self.hasEnteredEmailText && self.hasEnteredPasswordText;
}

- (BOOL)hasEnteredEmailText
{
    return nil != self.emailTextField.text && self.emailTextField.text.length > 4;
}

- (BOOL)hasEnteredPasswordText
{
    return nil != self.passwordTextField.text && self.passwordTextField.text.length > 5;
}

@end
