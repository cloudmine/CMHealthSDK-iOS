#import <ResearchKit/ResearchKit.h>

@class CMHLoginViewController;

@protocol CMHLoginViewControllerDelegate <NSObject>
@optional
- (void)loginViewControllerCancelled:(CMHLoginViewController *_Nonnull)viewController;
@end

@interface CMHLoginViewController : ORKTaskViewController

- (_Nonnull instancetype)initWithTitle:(NSString *_Nullable)title text:(NSString *_Nullable)text delegate:(id<CMHLoginViewControllerDelegate>)delegate;

@property (weak, nonatomic, nullable) id<CMHLoginViewControllerDelegate> loginDelegate;

- (instancetype)initWithTask:(nullable id<ORKTask>)task taskRunUUID:(nullable NSUUID *)taskRunUUID NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithTask:(nullable id<ORKTask>)task restorationData:(nullable NSData *)data delegate:(nullable id<ORKTaskViewControllerDelegate>)delegate NS_UNAVAILABLE;

@end
