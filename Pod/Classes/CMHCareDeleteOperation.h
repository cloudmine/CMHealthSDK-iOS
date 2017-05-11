#import <Foundation/Foundation.h>

@class CMHCareActivity;

@interface CMHCareDeleteOperation : NSOperation<NSSecureCoding>

- (nonnull instancetype)initWithActivity:(nonnull CMHCareActivity *)activity;

@end
