#import "CareKit+CMHealth.h"
#import <CloudMine/CloudMine.h>
#import "CMHObjectUtilities.h"
#import "CMHCarePlanStore.h"


@implementation OCKCarePlanActivity (CMHealth)

- (BOOL)isDataEquivalentOf:(OCKCarePlanActivity *_Nullable)other
{
    return cmhAreObjectsEqual(self.title, other.title) &&
    cmhAreObjectsEqual(self.text, other.text) &&
    cmhAreObjectsEqual(self.instructions, other.instructions) &&
    cmhAreObjectsEqual(self.schedule, other.schedule) &&
    (self.type == other.type) &&
    cmhAreObjectsEqual(self.identifier, other.identifier) &&
    cmhAreObjectsEqual(self.groupIdentifier, other.groupIdentifier) &&
    (self.resultResettable == other.resultResettable) &&
    cmhAreObjectsEqual(self.userInfo, other.userInfo);

}

@end

@implementation OCKCareSchedule (CMHealth)
@end

@implementation OCKCarePlanEventResult (CMHealth)
@end

@implementation OCKCarePlanThreshold (CMHealth)
@end

@implementation OCKPatient (CMHealth)

- (void)fetchProfileImageWithCompletion:(_Nullable CMHFetchProfileImageCompletion)block
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
