#import <CloudMine/CloudMine.h>
#import <ResearchKit/ResearchKit.h>

@interface CMHResult : CMObject

@property (nonatomic, nullable, readonly) ORKResult *rkResult;
@property (nonatomic, nullable, readonly) NSString *studyDescriptor;

- (_Nonnull instancetype)initWithResearchKitResult:(ORKResult *_Nullable)result andStudyDescriptor:(NSString *_Nullable)descriptor;

@end
