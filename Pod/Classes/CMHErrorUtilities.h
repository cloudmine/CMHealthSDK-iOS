#import <Foundation/Foundation.h>
#import "CMHErrors.h"

@interface CMHErrorUtilities : NSObject

+ (NSError *_Nonnull)errorWithCode:(CMHError)code localizedDescription:(NSString *_Nonnull)description;

@end
