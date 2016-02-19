#import <CloudMine/CloudMine.h>
#import <ResearchKit/ResearchKit.h>

@interface CMHResultWrapper : CMObject

- (_Nonnull instancetype)initWithResult:(ORKResult *_Nonnull)result studyDescriptor:(NSString *_Nullable)descriptor;
- (_Nonnull instancetype)initWithCoder:(NSCoder *_Nonnull)aDecoder;
- (ORKResult *_Nullable)wrappedResult;
+ (_Nonnull Class)wrapperClassForResultClass:(_Nonnull Class)resultClass;

@end
