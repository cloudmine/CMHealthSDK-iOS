#import "CMHBundler.h"

@interface CMHBundler ()
@property (nonatomic, readwrite, nonnull) NSBundle *bundle;
@end

@implementation CMHBundler

+ (instancetype)instance
{
    static CMHBundler *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [CMHBundler new];
        _sharedInstance.bundle = [self cmhBundle];
    });

    return _sharedInstance;
}

+ (NSBundle *_Nonnull)cmhBundle
{
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"CMHealth" ofType:@"bundle"]];
    NSAssert(nil != bundle, @"Failed to instansiate CMHealth Bundle");
    return bundle;
}

@end
