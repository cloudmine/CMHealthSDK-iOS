#import "CMHSignupViewController.h"
#import "CMHBundler.h"

@interface CMHSignupViewController ()

@end

@implementation CMHSignupViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

+ (_Nonnull instancetype)signupViewController
{
    UIViewController *vc = [UIStoryboard storyboardWithName:@"CMHSignup" bundle:[CMHBundler instance].bundle].instantiateInitialViewController;
    NSAssert(nil != vc, @"");
    NSAssert([vc isKindOfClass:[self class]], @"");
    return (CMHSignupViewController *)vc;
}

@end
