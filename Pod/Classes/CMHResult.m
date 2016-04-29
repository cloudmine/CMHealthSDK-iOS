#import "CMHResult.h"
#import "CMHConstants_internal.h"

@interface CMHResult()
@property (nonatomic, nullable, readwrite) ORKTaskResult *rkResult;
@property (nonatomic, nullable, readwrite) NSString *studyDescriptor;
@end

@implementation CMHResult

- (_Nonnull instancetype)initWithResearchKitResult:(ORKTaskResult *_Nonnull)result andStudyDescriptor:(NSString *_Nullable)descriptor;
{
    NSAssert(nil != result, @"CMHResult wrapper cannot be instantiated without an ORKTaskResult to wrap");
    NSAssert(nil != result.taskRunUUID, @"CMHealth can not process an ORKTaskResult without a unique taskRunUUID property; this one is nil");

    self = [super initWithObjectId:result.taskRunUUID.UUIDString];
    if (nil == self) return nil;

    self.rkResult = result;
    self.studyDescriptor = descriptor;

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    NSString *descriptor = [aDecoder decodeObjectForKey:CMHStudyDescriptorKey];
    if ([@"" isEqualToString:descriptor]) {
        self.studyDescriptor = nil;
    } else {
        self.studyDescriptor = descriptor;
    }

    self.rkResult = [aDecoder decodeObjectForKey:CMHResearchKitResultKey];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];

    if (nil == self.studyDescriptor) {
        [aCoder encodeObject:@"" forKey:CMHStudyDescriptorKey];
    } else {
        [aCoder encodeObject:self.studyDescriptor forKey:CMHStudyDescriptorKey];
    }

    [aCoder encodeObject:self.rkResult forKey:CMHResearchKitResultKey];
}

@end
