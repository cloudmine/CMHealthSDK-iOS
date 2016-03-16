#import "CMHTestCleaner.h"

@interface CMHTestCleaner ()
@property (nonatomic, nonnull) NSMutableArray<CMObject *> *objects;
@property (nonatomic, nonnull) NSMutableArray<NSString *> *filenames;

@property (nonatomic, nonnull) NSMutableArray<CMObject *> *failedObjects;
@property (nonatomic, nonnull) NSMutableArray<NSError *> *errors;
@end

@implementation CMHTestCleaner

- (instancetype)init
{
    self = [super init];
    if (nil == self) return nil;

    self.objects = [NSMutableArray new];
    self.filenames = [NSMutableArray new];
    self.errors = [NSMutableArray new];

    return self;
}

-(void)deleteConsent:(CMHConsent *)consent andResultsWithDescriptor:(NSString *)descriptor withCompletion:(CMHCleanupCompletion)block
{
    [self.objects addObject:consent];
    [self deleteAllObjectsAndFilesWithCompletion:block];
}

- (void)pushObject:(CMObject *)object
{
    if (nil == object) {
        return;
    }

    [self.objects addObject:object];
}

- (void)pushFileNamed:(NSString *)filename
{
    if (nil == filename) {
        return;
    }

    [self.filenames addObject:filename];
}

- (void)deleteAllObjectsAndFilesWithCompletion:(_Nonnull CMHCleanupCompletion)block
{
    [self deleteAllObjectsWithCompletion:^{
        block([self.errors copy]);
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
            [self.errors addObject:response.error];
            [self.failedObjects addObject:object];
        } else if (nil != response.objectErrors[object.objectId]) {
            [self.errors addObject:response.objectErrors[object.objectId]];
            [self.failedObjects addObject:object];
        }

        [self.objects removeObject:object];
        [self deleteAllObjectsWithCompletion:block];
    }];
}

@end
