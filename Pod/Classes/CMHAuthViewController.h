#import <UIKit/UIKit.h>

/**
 * Enumeration of the availble configurations of `CMHAuthViewController`
 */
typedef NS_ENUM(NSUInteger, CMHAuthType) {
    CMHAuthTypeSignup,
    CMHAuthTypeLogin
};

/**
 *  Protocol used by the `CMHAuthViewController` for callbacks after user
 *  takes given actions.
 */
@protocol CMHAuthViewDelegate <NSObject>

/**
 *  This method is invoked when the user cancels the current authentication action.
 *
 *  @param authType The configuration style of the `CMAuthViewController` that had
 *  been presented to the user.
 */
- (void)authViewCancelledType:(CMHAuthType)authType;

/**
 *  This method is invoked when the user chooses to submit validated authentication
 *  data.
 *
 *  @param email The validated email the user provided.
 *  @param password The password the user provide; guarrenteed to be at least 6 characters.
 */
- (void)authViewOfType:(CMHAuthType)authType didSubmitWithEmail:(NSString *_Nonnull)email andPassword:(NSString *_Nonnull)password;

@end

/**
 *  A preconfigued `UIViewController` for collecting and verifying user authentication
 *  data. This class should never be instantiated directly or embedded in a storyboard.
 *  This class is provided for convenience. The developer is free to build their own
 *  authentication screens.
 *
 *  To use this view controller, call one of the class factory methods and present the
 *  instance returned modally using the -presentViewController:animated:completion: method
 *  on `UIViewController`.
 *
 *  This class also provides full password reset functionality when configured for login.
 *  
 *  @see +signupViewController and +loginViewController
 */
@interface CMHAuthViewController : UIViewController

/**
 *  Returns a `CMHAuthViewController` configured for signup, suitable for
 *  modal presentation to the user.
 */
+ (_Nonnull instancetype)signupViewController;

/**
 *  Returns a `CMHAuthViewController` configured for login, suitable for
 *  modal presentation to the user.
 */
+ (_Nonnull instancetype)loginViewController;

/**
 *  The object to which user actions will be delegated to. Usually
 *  the view controller presenting the `CMHAuthViewController`.
 *
 *  @see CMHAuthViewDelegate protocol
 */
@property (weak, nonatomic, nullable) id<CMHAuthViewDelegate> delegate;

@end
