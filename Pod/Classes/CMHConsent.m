#import "CMHConsent_internal.h"
#import "Cocoa+CMHealth.h"

@implementation CMHConsent

- (_Nonnull instancetype)initWithConsentResult:(ORKTaskResult *)consentResult
{
    self = [super init];
    if (nil == self) return nil;

    self.consentResult = consentResult;

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    self.consentResult = [aDecoder decodeObjectForKey:@"consentResult"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.consentResult forKey:@"consentResult"];
}

@end
