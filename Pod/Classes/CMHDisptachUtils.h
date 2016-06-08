#import <Foundation/Foundation.h>

typedef void(^CMHDoneBlock)(void);
typedef void(^CMHWaitBlock)(_Nonnull CMHDoneBlock done);

void cmh_wait_until(_Nonnull CMHWaitBlock block);
