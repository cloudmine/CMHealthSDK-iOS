#import "CMHTestCleaner.h"
#import <CMHealth/CMHResult.h>
#import <CMHealth/CMHConstants_internal.h>
#import <CMHealth/CMHConsent_internal.h>

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
    if (self.objects.count <= 0) {
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
        [self deleteAllObjectsWithCompletion:block];
    }];
}

- (void)deleteAllFilesWithCompletion:(void (^)())block
{
    if (self.filenames.count <= 0) {
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
        [self deleteAllObjectsAndFilesWithCompletion:block];
    }];
}

@end
