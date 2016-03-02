#import <CloudMine/CloudMine.h>
#import <ResearchKit/ResearchKit.h>

typedef void(^CMHFetchSignatureCompletion)(UIImage *_Nullable signature, NSError *_Nullable error);

@interface CMHConsent : CMObject

@property (nonatomic, nullable, readonly) ORKTaskResult *consentResult;
@property (nonatomic, nullable, readonly) NSString *studyDescriptor;

- (void)fetchSignatureImageWithCompletion:(_Nullable CMHFetchSignatureCompletion)block;

@end
