#import "CMHLoginViewController.h"
#import "CMHLoginStepViewController.h"

@interface CMHLoginViewController ()<ORKTaskViewControllerDelegate>

@end

@implementation CMHLoginViewController

#pragma mark Lifecycle

- (_Nonnull instancetype)initWithTitle:(NSString *_Nullable)title text:(NSString *_Nullable)text delegate:(id<CMHLoginViewControllerDelegate>)delegate
{
    ORKLoginStep *loginStep = [[ORKLoginStep alloc] initWithIdentifier:@"CMHLoginStep"
                                                                 title:title
                                                                  text:text
                                              loginViewControllerClass:[CMHLoginStepViewController class]];

    ORKOrderedTask *loginTask = [[ORKOrderedTask alloc] initWithIdentifier:@"CMHLoginTask" steps:@[loginStep]];

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
        // TODO: Handle errors
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
    NSLog(@"User selected Login");
}

@end
