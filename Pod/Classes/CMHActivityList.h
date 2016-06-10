#import <CloudMine/CloudMine.h>
#import <CareKit/CareKit.h>

@interface CMHActivityList : CMObject

- (_Null_unspecified instancetype)init NS_UNAVAILABLE;
- (_Null_unspecified instancetype)initWithObjectId:(NSString *_Null_unspecified)theObjectId NS_UNAVAILABLE;

@property (nonatomic, nonnull, readonly) NSArray <OCKCarePlanActivity *> * activities;
- (_Nonnull instancetype)initWithActivities:(NSArray<OCKCarePlanActivity *> *_Nonnull)activities;

@end
