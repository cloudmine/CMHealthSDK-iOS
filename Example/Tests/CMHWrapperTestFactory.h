#import <ResearchKit/ResearchKit.h>

@interface CMHWrapperTestFactory : NSObject
+ (ORKTaskResult *)taskResult;
+ (BOOL)isEquivalent:(ORKTaskResult *)taskResult;
@end