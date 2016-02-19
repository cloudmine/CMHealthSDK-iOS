#import "CMHResultWrapper.h"
#import <objc/runtime.h>

@interface CMHResultWrapper ()
@property (nonatomic, nonnull) ORKResult *result;
@property (nonatomic, nonnull) NSString *studyDescriptor;
@end

@implementation CMHResultWrapper

- (_Nonnull instancetype)initWithResult:(ORKResult *_Nonnull)result studyDescriptor:(NSString *)descriptor;
{
    self = [super init];
    if (nil == self) return nil;

    NSAssert([CMHResultWrapper class] != [self class], @"Attempted to called initWithResult: directly on CMHResultWrapper. Only sublcasses returned by wrapperClassForResultClass: should be used.");

    self.result = result;
    self.studyDescriptor = descriptor;

    return self;
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    NSAssert([CMHResultWrapper class] != [self class], @"Attempted to called initWithCoder: directly on CMHResultWrapper. Only sublcasses returned by wrapperClassForResultClass: should be used.");

    Class runtimeClass = NSClassFromString([[self class] className]);
    self.result = [[runtimeClass alloc] initWithCoder:aDecoder];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSAssert([CMHResultWrapper class] != [self class], @"Attempted to called encodeWithCoder: directly on CMHResultWrapper. Only sublcasses returned by wrapperClassForResultClass: should be used.");

    [aCoder encodeObject:self.studyDescriptor forKey:@"studyDescriptor"];
    [self.result encodeWithCoder:aCoder];
}

#pragma mark Getters-Setters

- (ORKResult *)wrappedResult
{
    return self.result;
}

- (NSString *)studyDescriptor
{
    if (nil == _studyDescriptor) {
        return @"";
    }

    return _studyDescriptor;
}

// Returns the name of the wrapped class, rather than the wrapper class name itself
+ (NSString *)className
{
    NSError *regexError = nil;
    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"^CMH(\\w+)Wrapper$" options:0 error:&regexError];

    if (nil != regexError) {
        return [super className];
    }

    NSString *className = NSStringFromClass([self class]);
    NSArray<NSTextCheckingResult *> *matches = [regEx matchesInString:className options:0 range:NSMakeRange(0, className.length)];
    if (matches.count != 1) {
        return [super className];
    }

    NSTextCheckingResult *match = matches.firstObject;
    if(nil == match) {
        return [super className];
    }

    NSRange matchRange = [match rangeAtIndex:1];
    NSString *extractedName = [className substringWithRange:matchRange];
    if (nil == extractedName) {
        return [super className];
    }

    return extractedName;
}

// Returns a dynamically created subclass of CMHResultWrapper named for the class it will wrap
+ (Class)wrapperClassForResultClass:(Class)resultClass
{
    NSString *resultClassName = NSStringFromClass(resultClass);
    NSString *wrapperClassName = [NSString stringWithFormat:@"CMH%@Wrapper", resultClassName];

    Class exisitingWrapperClass = NSClassFromString(wrapperClassName);
    if (nil != exisitingWrapperClass) {
        return exisitingWrapperClass;
    }

    Class wrapperClass = objc_allocateClassPair([self class], [wrapperClassName cStringUsingEncoding:NSASCIIStringEncoding], 0);
    objc_registerClassPair(wrapperClass);
    
    return wrapperClass;
}

@end
