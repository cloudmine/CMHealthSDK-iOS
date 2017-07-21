#import "CMHCareFileMetadata.h"
#import "CMHConstants_internal.h"

@implementation CMHCareFileMetadata

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) { return nil; }
    
    _cmhOwnerId = [aDecoder decodeObjectForKey:CMHOwningUserKey];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.cmhOwnerId forKey:CMHOwningUserKey];
}

@end
