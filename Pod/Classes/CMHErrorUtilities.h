#import <CloudMine/CloudMine.h>
#import "CMHErrors.h"

@interface CMHErrorUtilities : NSObject

+ (NSError *_Nonnull)errorWithCode:(CMHError)code localizedDescription:(NSString *_Nonnull)description;
+ (NSError *_Nullable)errorForFileKind:(NSString *_Nullable)fileKind uploadResponse:(CMFileUploadResponse *_Nullable)response;

@end
