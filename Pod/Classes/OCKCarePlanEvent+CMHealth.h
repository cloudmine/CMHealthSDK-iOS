#import <CareKit/CareKit.h>

typedef void(^CMHCareSaveCompletion)(NSString *_Nullable uploadStatus, NSError *_Nullable error);

@interface OCKCarePlanEvent (CMHealth)

@property (nonatomic, nonnull, readonly) NSString *cmh_objectId;
- (void)cmh_saveWithCompletion:(_Nullable CMHCareSaveCompletion)block;

@end
