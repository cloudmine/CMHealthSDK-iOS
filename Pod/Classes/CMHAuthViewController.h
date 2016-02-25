#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CMHAuthType) {
    CMHAuthTypeSignup,
    CMHAuthTypeLogin
};

@protocol CMHAuthViewDelegate <NSObject>

- (void)authViewCancelledType:(CMHAuthType)authType;
- (void)authViewOfType:(CMHAuthType)authType didSubmitWithEmail:(NSString *_Nonnull)email andPassword:(NSString *_Nonnull)password;

@end

@interface CMHAuthViewController : UIViewController

+ (_Nonnull instancetype)signupViewController;
+ (_Nonnull instancetype)loginViewController;

@property (weak, nonatomic, nullable) id<CMHAuthViewDelegate> delegate;

@end
