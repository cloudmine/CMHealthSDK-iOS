#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>
#import <CloudMine/CloudMine.h>

typedef void(^CMHSaveCompletion)(NSString *_Nullable uploadStatus, NSError *_Nullable error);
typedef void(^CMHFetchCompletion)(NSArray *_Nullable results, NSError *_Nullable error);

@interface ORKResult (CMHealth)<CMCoding>
- (void)cmh_saveToStudyWithDescriptor:(NSString *_Nullable)descriptor withCompletion:(_Nullable CMHSaveCompletion)block;
+ (void)cmh_fetchUserResultsWithCompletion:(_Nullable CMHFetchCompletion)block;
@end
