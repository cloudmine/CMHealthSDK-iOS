#import <CareKit/CareKit.h>
#import <CloudMine/CMObject.h>

@interface CMHCareEvent : CMObject

- (_Nonnull instancetype)initWithEvent:(OCKCarePlanEvent *_Nonnull)event andUserId:(NSString *_Nonnull)cmhIdentifier;

@property (nonatomic, nonnull, readonly) OCKCarePlanEvent *ckEvent;

@end
