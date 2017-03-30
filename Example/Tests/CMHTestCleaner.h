#import <CloudMine/CloudMine.h>
#import <ResearchKit/ResearchKit.h>
#import <CMHealth/CMHealth.h>

@interface CMHTestCleaner : NSObject


- (void)deleteAllUserObjectsWithCompletion:(void (^_Nonnull)())block;
- (void)deleteConsent:(CMHConsent *_Nullable)consent andResultsWithDescriptor:(NSString *_Nullable)descriptor withCompletion:(void (^_Nonnull)())block;

@end
