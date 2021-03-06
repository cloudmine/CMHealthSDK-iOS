#import <Foundation/Foundation.h>

@class CMHCareEvent;
@class CMHCareActivity;

@interface CMHCarePushOperation : NSOperation<NSSecureCoding>

- (nonnull instancetype)initWithEvent:(nonnull CMHCareEvent *)event;
- (nonnull instancetype)initWithActivity:(nonnull CMHCareActivity *)activity;

@end
