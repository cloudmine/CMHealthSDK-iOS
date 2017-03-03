#import <Foundation/Foundation.h>

@interface CMHConfiguration : NSObject

+ (instancetype)sharedConfiguration;

@property (nonatomic, copy, nullable) NSString *sharedObjectUpdateSnippetName;

@end
