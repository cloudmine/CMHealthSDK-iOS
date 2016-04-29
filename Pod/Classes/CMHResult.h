#import <CloudMine/CloudMine.h>
#import <ResearchKit/ResearchKit.h>

@interface CMHResult : CMObject

@property (nonatomic, nullable, readonly) ORKTaskResult *rkResult;
@property (nonatomic, nullable, readonly) NSString *studyDescriptor;

- (_Nonnull instancetype)initWithResearchKitResult:(ORKTaskResult *_Nonnull)result andStudyDescriptor:(NSString *_Nullable)descriptor;

@end
