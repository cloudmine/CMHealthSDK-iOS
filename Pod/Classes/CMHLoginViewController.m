#import "CMHLoginViewController.h"
#import "CMHLoginStepViewController.h"
#import "CMHAlerter.h"
#import "CMHUser.h"

static NSString *const _Nonnull CMHLoginTaskIdentifier = @"CMHLoginTask";
static NSString *const _Nonnull CMHLoginStepIdentifier = @"CMHLoginStep";

@interface CMHLoginViewController ()<ORKTaskViewControllerDelegate>
@end

@implementation CMHLoginViewController

#pragma mark Lifecycle

- (_Nonnull instancetype)initWithTitle:(NSString *_Nullable)title text:(NSString *_Nullable)text delegate:(id<CMHLoginViewControllerDelegate>)delegate
{
    ORKLoginStep *loginStep = [[ORKLoginStep alloc] initWithIdentifier:CMHLoginStepIdentifier
                                                                 title:title
                                                                  text:text
                                              loginViewControllerClass:[CMHLoginStepViewController class]];

    ORKOrderedTask *loginTask = [[ORKOrderedTask alloc] initWithIdentifier:CMHLoginTaskIdentifier steps:@[loginStep]];

    self = [super initWithTask:loginTask taskRunUUID:nil];
    if (nil == self) return nil;

    self.delegate = self;
    self.loginDelegate = delegate;

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark Getters/Setters

- (void)setDelegate:(id<ORKTaskViewControllerDelegate>)delegate
{
    if (delegate != self) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"The delegate for %@ cannot be changed; instead use the loginDelegate", [self class]]
                                     userInfo:nil];
    }

    [super setDelegate:delegate];
}

#pragma mark ORKTaskViewControllerDelegate

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(NSError *)error
{
    if (nil != error) {
        NSString *message = [NSString localizedStringWithFormat:@"Error collecting authentication data; %@", error.localizedDescription];
        [CMHAlerter displayAlertWithTitle:NSLocalizedString(@"Error", nil)
                               andMessage:message
                         inViewController:self];
        return;
    }

    switch (reason) {
        case ORKTaskViewControllerFinishReasonFailed:
        case ORKTaskViewControllerFinishReasonSaved:
        case ORKTaskViewControllerFinishReasonDiscarded:
            [self handleCancel];
            break;
        case ORKTaskViewControllerFinishReasonCompleted:
            [self handleLogin];
            break;
        default:
            break;
    }
}

#pragma mark Helpers

- (void)handleCancel
{
    if (nil == self.loginDelegate || NO == [self.loginDelegate respondsToSelector:@selector(loginViewControllerCancelled:)]) {
        return;
    }

    [self.loginDelegate loginViewControllerCancelled:self];
}

- (void)handleLogin
{
    ORKResult *result = [self.result resultForIdentifier:CMHLoginStepIdentifier];
    NSAssert([result isKindOfClass:[ORKCollectionResult class]], @"Expecting Login Step to be an ORKCollectionResult, but received %@ instead", [result class]);

    ORKCollectionResult *loginResult = (ORKCollectionResult *)result;
    NSString *email = ((ORKTextQuestionResult *)[loginResult resultForIdentifier:ORKLoginFormItemIdentifierEmail]).textAnswer;
    NSString *password = ((ORKTextQuestionResult *)[loginResult resultForIdentifier:ORKLoginFormItemIdentifierPassword]).textAnswer;

    NSAssert(nil != email && nil != password, @"Login task should never return a nil email or password");

    [CMHUser.currentUser loginWithEmail:email password:password andCompletion:^(NSError * _Nullable error) {
        if (nil == self.loginDelegate || NO == [self.loginDelegate respondsToSelector:@selector(loginViewController:didLogin:error:)]) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loginDelegate loginViewController:self didLogin:(nil == error) error:error];
        });
    }];
}

@end
