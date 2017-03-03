#import <Foundation/Foundation.h>

@interface CMHConfiguration : NSObject

+ (nonnull instancetype)sharedConfiguration;

@property (nonatomic, copy, nullable) NSString *sharedObjectUpdateSnippetName;
@property (nonatomic, readonly) BOOL shouldShareUserProfile;

@end
