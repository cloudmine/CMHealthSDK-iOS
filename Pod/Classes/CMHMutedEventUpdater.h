#import <CareKit/CareKit.h>

@interface CMHMutedEventUpdater : NSObject

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store
                                event:(OCKCarePlanEvent *)event
                               result:(OCKCarePlanEventResult *)result
                                state:(OCKCarePlanEventState)state;

- (NSError *_Nullable)performUpdate;

@end
