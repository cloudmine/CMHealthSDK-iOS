#import <UIKit/UIKit.h>

@protocol CMHSignupViewDelegate <NSObject>

- (void)signupViewDidCancel;
- (void)signupViewDidCompleteWithEmail:(NSString *_Nonnull)email andPassword:(NSString *_Nonnull)password;

@end

@interface CMHSignupViewController : UIViewController

+ (_Nonnull instancetype)signupViewController;
@property (weak, nonatomic, nullable) id<CMHSignupViewDelegate> delegate;

@end
