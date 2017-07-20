#import "OCKPatient+CMHealth.h"
#import <CloudMine/CloudMine.h>
#import "CMHCarePlanStore.h"

@implementation OCKPatient (CMHealth)

- (void)cmh_fetchProfileImageWithCompletion:(_Nullable CMHFetchProfileImageCompletion)block
{
    if (![self.store isKindOfClass:[CMHCarePlanStore class]] ||
        nil == self.userInfo ||
        nil == self.userInfo[@"photoId"])
    {
        if (nil != block) {
            block(YES, nil, nil);
        }
        
        return;
    }
    
    NSString *photoId = (NSString *)self.userInfo[@"photoId"];
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
