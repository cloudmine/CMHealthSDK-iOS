#import "CMHMutedEventUpdater.h"
#import "OCKCarePlanEvent+CMHealth.h"

@interface CMHMutedEventUpdater ()

@property (nonatomic, nonnull) OCKCarePlanStore *store;
@property (nonatomic, nonnull) OCKCarePlanEvent *event;
@property (nonatomic, nullable) OCKCarePlanEventResult *result;
@property (nonatomic) OCKCarePlanEventState state;

@property (nonatomic, weak, nullable) id<OCKCarePlanStoreDelegate> holdDelegate;
@property (nonatomic, nonnull) dispatch_group_t updateGroup;

@end

@implementation CMHMutedEventUpdater

- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store
                                event:(OCKCarePlanEvent *)event
                               result:(OCKCarePlanEventResult *)result
                                state:(OCKCarePlanEventState)state
{
    self = [super init];
    if (nil == self) return nil;

    self.store = store;
    self.event = event;
    self.result = result;
    self.state = state;

    self.updateGroup = dispatch_group_create();

    return self;
}

- (void)performUpdate
{
    self.holdDelegate = self.store.delegate;
    self.store.delegate = self;

    dispatch_group_enter(self.updateGroup);
    [self.store updateEvent:self.event withResult:self.result state:self.state completion:^(BOOL success, OCKCarePlanEvent * _Nullable event, NSError * _Nullable error) {
        // TODO: collect and return errors
        NSLog(@"Updated Event");
    }];

    dispatch_group_wait(self.updateGroup, DISPATCH_TIME_FOREVER);

    if (self.store.delegate != self) {
        return;
    }
    
    self.store.delegate = self.holdDelegate;
}

#pragma mark OCKCarePlanStoreDelegate

- (void)carePlanStore:(OCKCarePlanStore *)store didReceiveUpdateOfEvent:(OCKCarePlanEvent *)event
{
    if ([event.cmh_objectId isEqualToString:self.event.cmh_objectId]) {
        dispatch_group_leave(self.updateGroup);
    } else {
        if (nil != self.holdDelegate && [self.holdDelegate respondsToSelector:@selector(carePlanStore:didReceiveUpdateOfEvent:)]) {
            [self.holdDelegate carePlanStore:store didReceiveUpdateOfEvent:event];
        }
    }
}

- (void)carePlanStoreActivityListDidChange:(OCKCarePlanStore *)store
{
    if (nil == self.holdDelegate || ![self.holdDelegate respondsToSelector:@selector(carePlanStoreActivityListDidChange:)]) {
        return;
    }

    [self.holdDelegate carePlanStoreActivityListDidChange:store];
}


@end
