#import <Foundation/Foundation.h>

@interface CMHAlerter : NSObject

+ (void)displayAlertWithTitle:(NSString *_Nullable)title
                   andMessage:(NSString *_Nonnull)message
             inViewController:(UIViewController *_Nonnull)viewController;

@end
