#import "CMHErrorUtilities.h"

@implementation CMHErrorUtilities

+ (NSError *_Nonnull)errorWithCode:(CMHError)code localizedDescription:(NSString *_Nonnull)description
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: description };
    NSError *error = [NSError errorWithDomain:CMHErrorDomain code:code userInfo:userInfo];
    return error;
}

@end
