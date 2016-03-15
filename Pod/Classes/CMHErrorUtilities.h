#import <CloudMine/CloudMine.h>
#import "CMHErrors.h"

@interface CMHErrorUtilities : NSObject

+ (NSError *_Nonnull)errorWithCode:(CMHError)code localizedDescription:(NSString *_Nonnull)description;
+ (NSError *_Nullable)errorForFileKind:(NSString *_Nullable)fileKind uploadResponse:(CMFileUploadResponse *_Nullable)response;
+ (NSError *_Nullable)errorForConsentWithObjectId:(NSString *_Nonnull)objectId uploadResponse:(CMObjectUploadResponse *_Nullable)response;

@end
