#import "OCKPatient+CMHealth.h"
#import <CloudMine/CloudMine.h>
#import "CMHCarePlanStore.h"
#import "CMHUserData.h"

NSString * const _Nonnull CMHPatientUserInfoUserDataKey = @"com.cloudmineinc.com.CMHealth.PhotoId";
NSString * const _Nonnull CMHPatientUserInfoPhotoIdKey = @"com.cloudmineinc.com.CMHealth.PatientData";

@implementation OCKPatient (CMHealth)

// TODO SOMEDAY: Allow updating the patient data from provider side

- (CMHUserData *)cmh_patientUserData
{
    if (![self.store isKindOfClass:[CMHCarePlanStore class]] ||
        nil == self.userInfo ||
        nil == self.userInfo[CMHPatientUserInfoUserDataKey] ||
        ![(NSObject *)self.userInfo[CMHPatientUserInfoUserDataKey] isKindOfClass:[CMHUserData class]])
    {
        return nil;
    }
    
    return (CMHUserData *)self.userInfo[CMHPatientUserInfoUserDataKey];
}

- (void)cmh_fetchProfileImageWithCompletion:(_Nullable CMHFetchProfileImageCompletion)block
{
    if (![self.store isKindOfClass:[CMHCarePlanStore class]] ||
        nil == self.userInfo ||
        nil == self.userInfo[CMHPatientUserInfoPhotoIdKey])
    {
        if (nil != block) {
            block(YES, nil, nil);
        }
        
        return;
    }
    
    NSString *photoId = (NSString *)self.userInfo[CMHPatientUserInfoPhotoIdKey];
    CMStoreOptions *shareOption = [CMStoreOptions new];
    shareOption.shared = YES;
    
    [[CMStore defaultStore] userFileWithName:photoId additionalOptions:shareOption callback:^(CMFileFetchResponse *response) {
        if (nil != response.error) {
            if (nil != block) {
                block(NO, nil, response.error);
            }
            return;
        }
        
        if (nil == response.file.fileData) {
            if (nil != block) {
                block(YES, nil, nil);
            }
            return;
        }
        
        UIImage *profileImage = [UIImage imageWithData:response.file.fileData];
        
        if (nil != block) {
            block(YES, profileImage, nil);
        }
    }];
}

@end
