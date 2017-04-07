#import <CareKit/CareKit.h>
#import <CloudMine/CloudMine.h>

@interface OCKCarePlanEvent (CMHealth) <CMCoding>

/**
 *  The unique identifier  assigned to this event based on its `OCKCarePlanActivity` 
 *  identifier, its schedule, and its days since start.
 */
@property (nonatomic, nonnull, readonly) NSString *cmh_uniqueId;

@end
