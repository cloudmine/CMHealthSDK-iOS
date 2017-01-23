#import <CareKit/CareKit.h>
#import <CloudMine/CMObject.h>

@interface CMHCareEvent : CMObject

- (_Nonnull instancetype)initWithEvent:(OCKCarePlanEvent *_Nonnull)event andUserId:(NSString *_Nonnull)cmhIdentifier;
- (BOOL)isDataEquivalentOf:(OCKCarePlanEvent *_Nullable)event;

@property (nonatomic, readonly) NSUInteger occurrenceIndexOfDay;
@property (nonatomic, readonly) NSUInteger numberOfDaysSinceStart;
@property (nonatomic, nonnull, readonly) NSDateComponents *date;
@property (nonatomic, nonnull, readonly) OCKCarePlanActivity *activity;
@property (nonatomic, readonly) OCKCarePlanEventState state;
@property (nonatomic, nullable, readonly) OCKCarePlanEventResult *result;

@end
