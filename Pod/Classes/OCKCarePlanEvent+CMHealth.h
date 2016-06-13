#import <CareKit/CareKit.h>

typedef void(^CMHCareSaveCompletion)(NSString *_Nullable uploadStatus, NSError *_Nullable error);

/**
 *  This category adds properties and methods to the `OCKCarePlanEvent` class which
 *  allow instances to be identified uniquely and saved to CloudMine's
 *  HIPAA compliant Connected Health Cloud.
 */
@interface OCKCarePlanEvent (CMHealth)

/**
 *  The unique identifier  assigned to this event based on its `OCKCarePlanActivity` 
 *  identifier, its schedule, and its days since start.
 *
 *  @warning the CareKit component of this SDK is experimental and subject to change. Your
 *  feedback is welcomed!
 */
@property (nonatomic, nonnull, readonly) NSString *cmh_objectId;

/**
 *  Save a representation of this `OCKCarePlanEvent` isntance to CloudMine.
 *  The event is given a unique identifier based on its `OCKCarePlanActivity` identifier,
 *  its schedule, and its days since start. Saving an event multiple times will update
 *  the instance of that event on CloudMine. The callback will provide a string value 
 *  of `created` or `updated` if the operation was successful.
 *
 *  @warning the CareKit component of this SDK is experimental and subject to change. Your
 *  feedback is welcomed!
 *
 *  @param block Executes when the request completes successfully or fails with an error.
 */
- (void)cmh_saveWithCompletion:(_Nullable CMHCareSaveCompletion)block;

@end
