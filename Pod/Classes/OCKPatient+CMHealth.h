#import <CareKit/CareKit.h>
#import <CMHealth/CMHUser.h>

extern NSString * const _Nonnull CMHPatientUserInfoUserDataKey;
extern NSString * const _Nonnull CMHPatientUserInfoPhotoIdKey;

@interface OCKPatient (CMHealth)

@property (nonatomic, nullable, readonly) CMHUserData *cmh_patientUserData;
- (void)cmh_fetchProfileImageWithCompletion:(_Nullable CMHFetchProfileImageCompletion)block;

@end
