#import <Foundation/Foundation.h>

@interface CMHBundler : NSObject

+ (instancetype _Nonnull)instance;
@property (nonatomic, readonly, nonnull) NSBundle *bundle;

@end
