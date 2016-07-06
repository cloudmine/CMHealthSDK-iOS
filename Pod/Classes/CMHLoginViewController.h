#import <ResearchKit/ResearchKit.h>

@class CMHLoginViewController;

@protocol CMHLoginViewControllerDelegate <NSObject>
@optional
- (void)loginViewControllerCancelled:(CMHLoginViewController *_Nonnull)viewController;
- (void)loginViewController:(CMHLoginViewController *_Nonnull)viewController didLogin:(BOOL)success error:(NSError *_Nullable)error;
@end

@interface CMHLoginViewController : ORKTaskViewController

- (_Nonnull instancetype)initWithTitle:(NSString *_Nullable)title text:(NSString *_Nullable)text delegate:(_Nullable id<CMHLoginViewControllerDelegate>)delegate;

@property (weak, nonatomic, nullable) id<CMHLoginViewControllerDelegate> loginDelegate;

- (_Null_unspecified instancetype)initWithTask:(nullable id<ORKTask>)task taskRunUUID:(nullable NSUUID *)taskRunUUID NS_UNAVAILABLE;
- (_Null_unspecified instancetype)initWithCoder:(NSCoder *_Null_unspecified)aDecoder NS_UNAVAILABLE;
- (_Null_unspecified instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (_Null_unspecified instancetype)initWithTask:(nullable id<ORKTask>)task restorationData:(nullable NSData *)data delegate:(nullable id<ORKTaskViewControllerDelegate>)delegate NS_UNAVAILABLE;

@end
