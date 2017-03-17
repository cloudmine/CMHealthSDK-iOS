#import "CMHCarePushOperation.h"
#import "CMHCareEvent.h"
#import "CMHCareActivity.h"
#import "CMHCareObjectSaver.h"
#import "CMHDisptachUtils.h"

@interface CMHCarePushOperation ()

@property (nonatomic, nonnull) id careObject;

@end

@implementation CMHCarePushOperation

#pragma mark Initialization

- (instancetype)init
{
    NSAssert(false, @"%s is unvailable on %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}

- (instancetype)initWithEvent:(CMHCareEvent *)event
{
    NSAssert(nil != event, @"Cannot instantiate %@ without an object to upload", [self class]);

    self = [super init];
    if (nil == self || nil == event) { return nil; }

    _careObject = event;
    self.queuePriority = NSOperationQueuePriorityHigh;

    return self;
}

- (instancetype)initWithActivity:(CMHCareActivity *)activity
{
    NSAssert(nil != activity, @"Cannot instantiate %@ without an object to upload", [self class]);

    self = [super init];
    if (nil == self || nil == activity) { return nil; }

    _careObject = activity;
    self.queuePriority = NSOperationQueuePriorityHigh;

    return self;
}

#pragma mark NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil == self) { return nil; }
    
    _careObject = [aDecoder decodeObjectForKey:@"careObject"];
    self.queuePriority = NSOperationQueuePriorityHigh;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.careObject forKey:@"careObject"];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

#pragma mark Overrides

- (void)main
{
    NSUInteger retryCount = 0;

    while(true) { // Retry loop
        if (self.isCancelled) {
            NSLog(@"[CMHealth] Operation cancelled");
            return;
        }

        __block NSString *saveStatus = nil;
        __block NSError *saveError = nil;

        cmh_wait_until(^(CMHDoneBlock  _Nonnull done) {
            [CMHCareObjectSaver saveCMHCareObject:self.careObject withCompletion:^(NSString * _Nullable status, NSError * _Nullable error) {
                saveStatus = status;
                saveError = error;

                done();
            }];
        });

        if (nil == saveStatus) {
            NSTimeInterval sleepTime = [CMHCarePushOperation sleepTimeForRetryCount:retryCount];
            retryCount += 1;

            NSLog(@"[CMHEALTH] Error uploading Care Object via queue %@, retrying after: %f. -> %@", saveError.localizedDescription, sleepTime, self.careObject);
            if (self.isCancelled) {
                NSLog(@"[CMHealth] Operation cancelled");
                return;
            }

            [NSThread sleepForTimeInterval:sleepTime];
        } else {
            NSLog(@"[CMHEALTH] Care Object uploaded via queue with status: %@. -> %@", saveStatus, self.careObject);
            break;
        }
    }
}

#pragma mark Helpers

+ (NSTimeInterval)sleepTimeForRetryCount:(NSUInteger)count
{
    switch (count) {
        case 0:
            return 0.1f;
        case 1:
            return 1.0f;
        case 2:
            return 2.0f;
        case 3:
            return 5.0f;
        case 4:
            return 10.0f;
        case 5:
            return 15.0f;
        default:
            return 30.0f;
    }
}

@end
