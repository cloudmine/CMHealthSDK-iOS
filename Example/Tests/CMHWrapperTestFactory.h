#import <ResearchKit/ResearchKit.h>

/* Expose private interface for testing purposes
   Note this is asserted in CMIntegrationTests.m such that should the internal
   API ever change, the tests will fail and alert us to that fact */
@interface ORKLocation (CMHTestable)

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                            region:(CLCircularRegion *)region
                         userInput:(NSString *)userInput
                 addressDictionary:(NSDictionary *)addressDictionary;

@end

# pragma mark CMHWrapperTestFactory Interface

@interface CMHWrapperTestFactory : NSObject

+ (ORKTaskResult *)taskResult;
+ (BOOL)isEquivalent:(ORKTaskResult *)taskResult;

+ (NSDateComponents *)testDateComponents;
+ (BOOL)isEquivalentToTestDateComponents:(NSDateComponents *)comps;

+ (ORKLocation *)location;

@end