#import <CloudMine/CloudMine.h>
#import <CareKit/CareKit.h>

@interface CMHActivityList : CMObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithObjectId:(NSString *)theObjectId NS_UNAVAILABLE;

@property (nonatomic, nonnull, readonly) NSArray <OCKCarePlanActivity *> * activities;
- (_Nonnull instancetype)initWithActivities:(NSArray<OCKCarePlanActivity *> *_Nonnull)activities;

@end
