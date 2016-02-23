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
    UIViewController *vc = [[UIStoryboard storyboardWithName:@"CMHSignup" bundle:[CMHBundler instance].bundle] instantiateInitialViewController];
    NSAssert(nil != vc, @"Failed to load CMHSignupViewController from Storyboard");
    NSAssert([vc isKindOfClass:[self class]], @"Expected to load %@ but got %@", [self class], [vc class]);
    return (CMHSignupViewController *)vc;
}

@end
