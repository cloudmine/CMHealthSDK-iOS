#import <ResearchKit/ResearchKit.h>

@interface CMHWrapperTestFactory : NSObject
+ (ORKTaskResult *)taskResult;
+ (BOOL)isEquivalent:(ORKTaskResult *)taskResult;
+ (NSDateComponents *)testDateComponents;
+ (BOOL)isEquivalentToTestDateComponents:(NSDateComponents *)comps;
@end