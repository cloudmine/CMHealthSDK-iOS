#import <CareKit/CareKit.h>
#import <CMHealth/CMHUser.h>

@interface OCKPatient (CMHealth)

- (void)cmh_fetchProfileImageWithCompletion:(_Nullable CMHFetchProfileImageCompletion)block;

@end
