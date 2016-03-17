#import "CMHTestCleaner.h"
#import <CMHealth/CMHResult.h>
#import <CMHealth/CMHConstants_internal.h>
#import <CMHealth/CMHConsent_internal.h>
#import <CMHealth/CMHInternalUser.h>
#import <CMHealth/CMHInternalProfile.h>

static const NSInteger MaxRetryCount = 1;

@interface CMHInternalUser (TestCleaner)
@property (nonatomic, nullable) CMHInternalProfile *profile;
@end

@interface CMHTestCleaner ()
@property (nonatomic, nonnull) NSMutableArray<CMObject *> *objects;
@property (nonatomic, nonnull) NSMutableArray<NSString *> *filenames;

@property (nonatomic, nonnull) NSMutableArray<CMObject *> *failedObjects;
@property (nonatomic, nonnull) NSMutableArray<NSString *> *failedFilenames;
@end

@implementation CMHTestCleaner

- (instancetype)init
{
    self = [super init];
    if (nil == self) return nil;

    self.objects = [NSMutableArray new];
    self.filenames = [NSMutableArray new];

    return self;
}

- (void)deleteConsent:(CMHConsent *)consent andResultsWithDescriptor:(NSString *)descriptor withCompletion:(void (^)())block
{
    [self.objects addObject:consent];
    [self.objects addObject:CMHInternalUser.currentUser.profile];
    [self.filenames addObject:consent.signatureImageFilename];
    [self.filenames addObject:consent.pdfFileName];

    NSString *query = [NSString stringWithFormat:@"[%@ = \"%@\", %@ = \"%@\"]", CMInternalClassStorageKey, [CMHResult class], CMHStudyDescriptorKey, descriptor];

    [CMStore.defaultStore searchUserObjects:query additionalOptions:nil callback:^(CMObjectFetchResponse *response) {

        for (CMHResult *wrappedResult in response.objects) {
            [self.objects addObject:wrappedResult];
        }

        [self deleteAllObjectsAndFilesWithCompletion:block];
    }];
}

- (void)deleteAllObjectsAndFilesWithCompletion:(void (^)())block
{
    [self deleteAllObjectsWithCompletion:^{
        [self deleteAllFilesWithCompletion:^{
            block();
        }];
    }];
}

- (void)deleteAllObjectsWithCompletion:(void (^)())block
{
    [self deleteAllObjectsWithRetryCount:0 andCompletion:block];
}

- (void)deleteAllObjectsWithRetryCount:(NSInteger)retryCount andCompletion:(void (^)())block
{
    if (self.objects.count <= 0) {
        if (self.failedObjects.count > 0 && retryCount < MaxRetryCount) {
            [self.objects addObjectsFromArray:self.failedObjects];
            self.failedObjects = [NSMutableArray new];

            [self deleteAllObjectsWithRetryCount:(retryCount + 1) andCompletion:block];

            return;
        }

        block();
        return;
    }

    CMObject *object = self.objects.firstObject;

    [[CMStore defaultStore] deleteUserObject:object additionalOptions:nil callback:^(CMDeleteResponse *response) {
        if (nil != response.error) {
            [self.failedObjects addObject:object];
        } else if (nil != response.objectErrors[object.objectId]) {
            [self.failedObjects addObject:object];
        }

        [self.objects removeObject:object];
        [self deleteAllObjectsWithRetryCount:retryCount andCompletion:block];
    }];
}

- (void)deleteAllFilesWithCompletion:(void (^)())block
{
    [self deleteAllFilesWithRetryCount:0 andCompletion:block];
}

- (void)deleteAllFilesWithRetryCount:(NSInteger)retryCount andCompletion:(void (^)())block
{
    if (self.filenames.count <= 0) {
        if (self.failedFilenames.count > 0 && retryCount < MaxRetryCount) {
            [self.filenames addObjectsFromArray:self.failedFilenames];
            self.failedFilenames = [NSMutableArray new];

            [self deleteAllFilesWithRetryCount:(retryCount + 1) andCompletion:block];

            return;
        }

        block();
        return;
    }

    NSString *filename = self.filenames.firstObject;

    [CMStore.defaultStore deleteUserFileNamed:filename additionalOptions:nil callback:^(CMDeleteResponse *response) {
        if (nil != response.error) {
            [self.failedFilenames addObject:filename];
        } else if (response.objectErrors.allValues.count > 0) {
            [self.failedFilenames addObject:filename];
        }

        [self.filenames removeObject:filename];
        [self deleteAllFilesWithRetryCount:retryCount andCompletion:block];
    }];
}

@end
