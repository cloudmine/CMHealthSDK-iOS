#import "CMHDisptachUtils.h"

void cmh_wait_until(_Nonnull CMHWaitBlock block)
{
    dispatch_group_t doneGroup = dispatch_group_create();

    CMHDoneBlock done = ^{
        dispatch_group_leave(doneGroup);
    };

    dispatch_group_enter(doneGroup);
    block(done);

    dispatch_group_wait(doneGroup, DISPATCH_TIME_FOREVER);
}