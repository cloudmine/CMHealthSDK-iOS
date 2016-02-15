#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>
#import <CloudMine/CloudMine.h>

#import "CMHUserData.h"
#import "CMHUser.h"
#import "ORKResult+CMHealth.h"

@interface CMHealth : NSObject

+ (void)setAppIdentifier:(NSString *_Nonnull)identifier appSecret:(NSString *_Nonnull)secret;

@end