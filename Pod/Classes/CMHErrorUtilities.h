#import <CloudMine/CloudMine.h>
#import "CMHErrors.h"

@interface CMHErrorUtilities : NSObject

+ (NSError *_Nonnull)errorWithCode:(CMHError)code localizedDescription:(NSString *_Nonnull)description;

+ (NSError *_Nullable)errorForFileKind:(NSString *_Nullable)fileKind uploadResponse:(CMFileUploadResponse *_Nullable)response;

+ (NSError *_Nullable)errorForKind:(NSString *_Nullable)kind objectId:(NSString *_Nonnull)objectId uploadResponse:(CMObjectUploadResponse *_Nullable)response;

+ (NSError *_Nullable)errorForKind:(NSString *_Nullable)kind fetchResponse:(CMObjectFetchResponse *_Nullable)response;

+ (NSError *_Nullable)errorForAccountResult:(CMUserAccountResult)resultCode;

+ (NSError *_Nullable)errorForFetchWithResponse:(CMObjectFetchResponse *_Nullable)response;

+ (NSError *_Nullable)errorForInternalError:(NSError *_Nullable)error withPrefix:(NSString *_Nonnull)prefix;

+ (CMHError)localCodeForCloudMineCode:(CMErrorCode)code;

+ (NSString *_Nonnull)messageForCode:(CMHError)errorCode;

@end
