#import <CareKit/CareKit.h>
#import <CloudMine/CMCoding.h>

@interface CMHCareEventResult : NSObject<CMCoding>

- (_Nonnull instancetype)initWithEventResult:(OCKCarePlanEventResult *_Nonnull)result;

@property (nonatomic, nullable, readonly) OCKCarePlanEventResult *result;

@end
