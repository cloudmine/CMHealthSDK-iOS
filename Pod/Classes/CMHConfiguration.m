#import "CMHConfiguration.h"

@implementation CMHConfiguration

+ (instancetype)sharedConfiguration
{
    static dispatch_once_t onceToken;
    static CMHConfiguration *configInstance = nil;
    
    dispatch_once(&onceToken, ^{
        configInstance = [self new];
    });
    
    return configInstance;
}

- (BOOL)shouldShareUserProfile
{
    return nil != self.sharedObjectUpdateSnippetName;
}

@end
