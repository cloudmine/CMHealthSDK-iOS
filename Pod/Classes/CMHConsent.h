#import <CloudMine/CloudMine.h>
#import <ResearchKit/ResearchKit.h>

@interface CMHConsent : CMObject

@property (nonatomic, nullable, readonly) ORKTaskResult *consentResult;
@property (nonatomic, nullable, readonly) NSString *studyDescriptor;

@end
