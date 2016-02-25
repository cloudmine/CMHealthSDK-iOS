#import "CMHAuthViewController.h"
#import "CMHBundler.h"
#import "CMHInputValidators.h"
#import "CMHAlerter.h"

static NSString *const CMHAuthStoryboardName = @"CMHAuth";

typedef NS_ENUM(NSUInteger, CHMAuthViewControllerConfig) {
    CHMAuthViewControllerConfigSignup,
    CHMAuthViewControllerConfigLogin
};

@interface CMHAuthViewController ()
@property (weak, nonatomic) IBOutlet UINavigationItem *navItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UILabel *topMessageLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (nonatomic) CHMAuthViewControllerConfig authType;
@end

@implementation CMHAuthViewController

#pragma mark Factory Instantiation

+ (_Nonnull instancetype)signupViewController
{
    CMHAuthViewController *signupVC = [self viewControllerFromStoryboard];
    signupVC.authType = CHMAuthViewControllerConfigSignup;
    return signupVC;
}

+ (_Nonnull instancetype)loginViewController
{
    CMHAuthViewController *loginVC = [self viewControllerFromStoryboard];
    loginVC.authType = CHMAuthViewControllerConfigLogin;
    return loginVC;
}

+ (_Nonnull instancetype)viewControllerFromStoryboard
{
    UIViewController *vc = [[UIStoryboard storyboardWithName:CMHAuthStoryboardName bundle:[CMHBundler instance].bundle] instantiateInitialViewController];
    NSAssert(nil != vc, @"Failed to load %@ from Storyboard", [self class]);
    NSAssert([vc isKindOfClass:[self class]], @"Expected to load %@ but got %@", [self class], [vc class]);
    return (CMHAuthViewController *)vc;
}

#pragma mark Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    switch (self.authType) {
        case CHMAuthViewControllerConfigLogin:
            self.navItem.title = NSLocalizedString(@"Log In", nil);
            self.topMessageLabel.text = NSLocalizedString(@"Please log in to your account to store and access your research data.", nil);
            self.forgotPasswordButton.hidden = NO;
            break;
        default:
            self.navItem.title = NSLocalizedString(@"Registration", nil);
            self.topMessageLabel.text = NSLocalizedString(@"Please create an account to store and access your research data.", nil);
            self.forgotPasswordButton.hidden = YES;
    }

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

    [self.delegate authViewDidSubmitWithEmail:self.emailTextField.text andPassword:self.passwordTextField.text];
}

- (IBAction)cancelButtonDidPress:(UIBarButtonItem *)sender
{
    [self.delegate authViewDidCancel];
}
- (IBAction)forgotPasswordButtonDidPress:(UIButton *)sender
{

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
