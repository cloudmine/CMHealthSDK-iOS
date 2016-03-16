#import <CloudMine/CloudMine.h>
#import <ResearchKit/ResearchKit.h>
#import <CMHealth/CMHealth.h>

typedef void(^CMHCleanupCompletion)(NSArray <NSError *> *_Nonnull);

@interface CMHTestCleaner : NSObject

- (void)deleteConsent:(CMHConsent *_Nullable)consent andResultsWithDescriptor:(NSString *_Nullable)descriptor withCompletion:(_Nonnull CMHCleanupCompletion)block;

@end
