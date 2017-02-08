#import <CareKit/CareKit.h>
#import <CloudMine/CloudMine.h>

typedef void(^CMHCareSaveCompletion)(NSString *_Nullable uploadStatus, NSError *_Nullable error);

/**
 *  This category adds properties and methods to the `OCKCarePlanEvent` class which
 *  allow instances to be identified uniquely and saved to CloudMine's
 *  HIPAA compliant Connected Health Cloud.
 */
@interface OCKCarePlanEvent (CMHealth) <CMCoding>

/**
 *  The unique identifier  assigned to this event based on its `OCKCarePlanActivity` 
 *  identifier, its schedule, and its days since start.
 *
 *  @warning the CareKit component of this SDK is experimental and subject to change. Your
 *  feedback is welcomed!
 */
@property (nonatomic, nonnull, readonly) NSString *cmh_uniqueId;

@end
