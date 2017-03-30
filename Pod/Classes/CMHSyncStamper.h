#import <Foundation/Foundation.h>

@interface CMHSyncStamper : NSObject

- (nonnull instancetype)initWithCMHIdentifier:(nonnull NSString *)cmhIdentifier;

- (void)saveEventLastSyncTime:(nonnull NSDate *)date;
- (void)saveActivityLastSyncTime:(nonnull NSDate *)date;
- (void)forgetSyncTimes;

@property (nonatomic, nonnull, readonly) NSString *eventLastSyncStamp;
@property (nonatomic, nonnull, readonly) NSString *activityLastSyncStamp;

@end
