#import <CareKit/CareKit.h>
#import <CMHealth/CMHUser.h>

extern NSString * const _Nonnull CMHPatientUserInfoUserDataKey;
extern NSString * const _Nonnull CMHPatientUserInfoPhotoIdKey;

@interface OCKPatient (CMHealth)

/**
 *  This property will be populated for patient objects fetched by 
 *  a Care Provider from an instance of `CMHCarePlanStore`.
 *  It exposes the same `CMHUserData` that is created and configurable
 *  by the patient through their `CMHUser` instance.
 */
@property (nonatomic, nullable, readonly) CMHUserData *cmh_patientUserData;

/**
 *  Fetch the patient's profile image, if one exists, or nil if not.
 *  This method is meant for use in conjunction with patient objects fetched by
 *  an instance of `CMHCarePlanStore` in a Care Provider app context.
 *
 *  @param block Executes when image has been fetched successfully or fails with an error.
 */
- (void)cmh_fetchProfileImageWithCompletion:(_Nullable CMHFetchProfileImageCompletion)block;

@end
