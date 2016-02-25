#import <UIKit/UIKit.h>

@protocol CMHAuthViewDelegate <NSObject>

- (void)authViewDidCancel;
- (void)authViewDidSubmitWithEmail:(NSString *_Nonnull)email andPassword:(NSString *_Nonnull)password;

@end

@interface CMHAuthViewController : UIViewController

+ (_Nonnull instancetype)signupViewController;
+ (_Nonnull instancetype)loginViewController;

@property (weak, nonatomic, nullable) id<CMHAuthViewDelegate> delegate;

@end
