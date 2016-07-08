#import <ResearchKit/ResearchKit.h>

@class CMHLoginViewController;

/**
 *  Protocol used by the `CMHLoginViewController` for callbacks after
 *  the takes given actions.
 */
@protocol CMHLoginViewControllerDelegate <NSObject>
@optional

/**
 *  This method is invoked when user cancels the current login action.
 *
 *  @param viewController The login view controller which was presented to the user
 *  and from which they selected the cancel action.
 */
- (void)loginViewControllerCancelled:(CMHLoginViewController *_Nonnull)viewController;

/**
 *  This method is invoked after the user has entered valid login credentials and the
 *  SDK has attempted to authenticate the user using them.
 *
 *  @param viewController The login view controller which was presented to the user and
 *  from which they initiated the login action.
 *  @param success YES if the user was successfully logged in with the credentials they provided.
 *  @param error The error which occurred if authentication was not successful
 */
- (void)loginViewController:(CMHLoginViewController *_Nonnull)viewController didLogin:(BOOL)success error:(NSError *_Nullable)error;
@end

/**
 *  A preconfigued `ORKTaskViewController` for collecting and verifying user authentication
 *  data. This class wraps around `ORKLoginStepViewController` and implements all CloudMine
 *  specific login and password reset behavior. It should not be embedded in a storyboard.
 *
 *  This class is provided for convenience. The developer is free to build their own
 *  authentication screens.
 *
 *  To use this view controller, create one with `-initWithTitle:text:delegate:`
 *  and present the instance returned modally using  `-presentViewController:animated:completion:`.
 *
 *  @see -initWithTitle:text:delegate: and `CMHLoginViewControllerDelegate`
 */
@interface CMHLoginViewController : ORKTaskViewController

/**
 *  Initializer for creating properly configured `CMHLoginViewController` instances.
 *
 *  @see `CMHLoginViewControllerDelegate`
 *
 *  @param title The localized title to display to the user.
 *  @param text The localized text to display below to the user below the title.
 *  @param delegate The delegate to receive callbacks when the user takes action from the login view controller
 */
- (_Nonnull instancetype)initWithTitle:(NSString *_Nullable)title text:(NSString *_Nullable)text delegate:(_Nullable id<CMHLoginViewControllerDelegate>)delegate;

/**
 * The delegate to receive callbacks when the user takes action from the login view controller
 *
 *  @see `CMHLoginViewControllerDelegate`
 */
@property (weak, nonatomic, nullable) id<CMHLoginViewControllerDelegate> loginDelegate;

- (_Null_unspecified instancetype)initWithTask:(nullable id<ORKTask>)task taskRunUUID:(nullable NSUUID *)taskRunUUID NS_UNAVAILABLE;
- (_Null_unspecified instancetype)initWithCoder:(NSCoder *_Null_unspecified)aDecoder NS_UNAVAILABLE;
- (_Null_unspecified instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (_Null_unspecified instancetype)initWithTask:(nullable id<ORKTask>)task restorationData:(nullable NSData *)data delegate:(nullable id<ORKTaskViewControllerDelegate>)delegate NS_UNAVAILABLE;

@end
