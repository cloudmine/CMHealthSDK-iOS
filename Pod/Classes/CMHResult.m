#import "CMHResult.h"
#import "CMHConstants_internal.h"

@interface CMHResult()
@property (nonatomic, nullable, readwrite) ORKResult *rkResult;
@property (nonatomic, nullable, readwrite) NSString *studyDescriptor;
@end

@implementation CMHResult

- (_Nonnull instancetype)initWithResearchKitResult:(ORKResult *_Nullable)result andStudyDescriptor:(NSString *_Nullable)descriptor;
{
    self = [super init];
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
