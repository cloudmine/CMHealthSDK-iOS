#import <Foundation/Foundation.h>

@interface CMHSyncStamper : NSObject

- (nonnull instancetype)initWithCMHIdentifier:(nonnull NSString *)cmhIdentifier;

- (void)saveLastSyncTime:(nonnull NSDate *)date;
- (void)forgetSyncTime;

@property (nonatomic, nonnull, readonly) NSString *lastSyncStamp;

@end
