#import "ORKResult+CMHealth.h"
#import <objc/runtime.h>
#import "CMHResultWrapper.h"

void acm_swizzle(Class class, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@implementation ORKResult (CMHealth)

- (void)cmh_saveWithCompletion:(_Nullable CMHSaveCompletion)block
{
    Class resultWrapperClass = [CMHResultWrapper wrapperClassForResultClass:[self class]];

    NSAssert([[resultWrapperClass class] isSubclassOfClass:[CMHResultWrapper class]],
             @"Fatal Error: Result wrapper class not a result of ACMResultWrapper");

    CMHResultWrapper *resultWrapper = [[resultWrapperClass alloc] initWithResult:self];

    [resultWrapper saveWithUser:[CMStore defaultStore].user callback:^(CMObjectUploadResponse *response) {
        if (nil == block) {
            return;
        }

        if (nil != response.error) {
            block(nil, response.error);
            return;
        }

        // Thought: as we expand the functionality of the SDK, would it make sense to return the objectId to the
        // the caller so they could later fetch the same results? This would esepcially make sense if we eventually
        // want to support serializing and uploading things other than results, such as in-progress-ORKTasks that might
        // be continued by the user later
        if (nil == response.uploadStatuses || nil == [response.uploadStatuses objectForKey:resultWrapper.objectId]) {
            NSError *nullStatusError = [ORKResult errorWithMessage:@"CloudMine upload status not returned" andCode:100];
            block(nil, nullStatusError);
            return;
        }

        NSString *resultUploadStatus = [response.uploadStatuses objectForKey:resultWrapper.objectId];
        if(![@"created" isEqualToString:resultUploadStatus] && ![@"updated" isEqualToString:resultUploadStatus]) {
            NSString *message = [NSString localizedStringWithFormat:@"CloudMine invalid upload status returned: %@", resultUploadStatus];
            NSError *invalidStatusError = [ORKResult errorWithMessage:message andCode:101];
            block(nil, invalidStatusError);
            return;
        }

        block(resultUploadStatus, nil);
    }];
}

+ (void)cmh_fetchUserResultsWithCompletion:(_Nullable CMHFetchCompletion)block;
{
    Class wrapperClass = [CMHResultWrapper wrapperClassForResultClass:[self class]];
    NSString *queryString = [NSString stringWithFormat:@"[%@ = \"%@\"]", CMInternalClassStorageKey, [self class]];

    [[CMStore defaultStore] searchUserObjects:queryString
                            additionalOptions:nil
                                     callback:^(CMObjectFetchResponse *response)
     {
         NSMutableArray *mutableResults = [NSMutableArray new];
         for (id object in response.objects) {
             if ([object class] != wrapperClass || ![[object wrappedResult] isKindOfClass:[self class]]) {
                 continue;
             }

             [mutableResults addObject:[object wrappedResult]];
         }

         block([mutableResults copy], nil);
     }];
}

# pragma mark Private

+ (NSError * _Nullable)errorWithMessage:(NSString * _Nonnull)message andCode:(NSInteger)code
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: message };
    NSError *error = [NSError errorWithDomain:@"ACMResultSaveError" code:code userInfo:userInfo];
    return error;
}

@end

@implementation ORKConsentSignature (CMHealth)
@end

@implementation UIImage (CMHealth)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        acm_swizzle([self class], @selector(encodeWithCoder:), @selector(acm_encodeWithCoder:));
    });
}

- (void)acm_encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder isKindOfClass:[CMObjectEncoder class]]) {
        NSLog(@"ENCODING UIImage HAS BEEN SWIZZLED");
        return;
    }

    [self acm_encodeWithCoder:aCoder];
}

@end

@implementation NSUUID (CMHealth)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        acm_swizzle([self class], @selector(initWithCoder:), @selector(initWithCoder_acm:));
        acm_swizzle([self class], @selector(encodeWithCoder:), @selector(acm_encodeWithCoder:));
    });
}

- (void)acm_encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder isKindOfClass:[CMObjectEncoder class]]) {
        [aCoder encodeObject:self.UUIDString forKey:@"UUIDString"];
        return;
    }

    [self acm_encodeWithCoder:aCoder];
}

- (instancetype)initWithCoder_acm:(NSCoder *)decoder
{
    if ([decoder isKindOfClass:[CMObjectDecoder class]]) {
        self = [[NSUUID alloc] initWithUUIDString:[decoder decodeObjectForKey:@"UUIDString"]];
        return self;
    }
    
    return [self initWithCoder_acm:decoder];
}

@end
