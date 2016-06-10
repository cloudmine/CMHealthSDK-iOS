#import <CareKit/CareKit.h>

@interface CMHMutedEventUpdater : NSObject

- (_Nonnull instancetype)initWithCarePlanStore:(OCKCarePlanStore *_Nonnull)store
                                         event:(OCKCarePlanEvent *_Nonnull)event
                                        result:(OCKCarePlanEventResult *_Nullable)result
                                         state:(OCKCarePlanEventState)state;

- (NSError *_Nullable)performUpdate;

@end
