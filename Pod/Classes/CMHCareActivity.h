#import <CareKit/CareKit.h>
#import <CloudMine/CMObject.h>

@interface CMHCareActivity : CMObject

- (nonnull instancetype)initWithActivity:(nonnull OCKCarePlanActivity *)activity andUserId:(nonnull NSString *)cmhIdentifier;

@property (nonatomic, nonnull, readonly) OCKCarePlanActivity *ckActivity;
@property (nonatomic) BOOL isDeleted;

@end
