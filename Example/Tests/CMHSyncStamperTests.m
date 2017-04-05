#import <CMHealth/CMHSyncStamper.h>

SpecBegin(CMHSyncStamper)

describe(@"CMHSyncStamper", ^{
    static NSString *const kCMHEpochStamp = @"1970-01-01T00:00:00Z";
    static NSString *const kCMHFakeIdOne  = @"fake-id-1";
    static NSString *const kCMHFakeIdTwo  = @"fake-id-2";
    
    static NSString *const kCMHTestStampOne     = @"2014-01-16T14:06:00Z";
    static const NSTimeInterval kCMHTestDateOne = 1389881160;
    
    static NSString *const kCMHTestStampTwo     = @"2015-11-06T07:53:00Z";
    static const NSTimeInterval kCMHTestDateTwo = 1446796380;
    
    beforeAll(^{
        CMHSyncStamper *stamperOne = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdOne];
        [stamperOne forgetSyncTime];
        
        CMHSyncStamper *stamperTwo = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdTwo];
        [stamperTwo forgetSyncTime];
    });
    
    it(@"should return the Unix Epoch if no sync times have been saved", ^{
        CMHSyncStamper *stamper = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdOne];
        
        expect(stamper.lastSyncStamp).to.equal(kCMHEpochStamp);
    });
    
    it(@"should update the sync time", ^{
        CMHSyncStamper *stamper = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdOne];
        NSDate *newDate = [NSDate dateWithTimeIntervalSince1970:kCMHTestDateOne];
        
        [stamper saveLastSyncTime:newDate];
        
        expect(stamper.lastSyncStamp).to.equal(kCMHTestStampOne);
    });
    
    it(@"should remember sync times for one user w/o impacting a new one", ^{
        CMHSyncStamper *stamperOne = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdOne];
        CMHSyncStamper *stamperTwo = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdTwo];
        
        expect(stamperOne.lastSyncStamp).to.equal(kCMHTestStampOne);
        expect(stamperTwo.lastSyncStamp).to.equal(kCMHEpochStamp);
    });
    
    it(@"should update sync times for a new user w/o impacting the old one", ^{
        CMHSyncStamper *stamperOne = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdOne];
        CMHSyncStamper *stamperTwo = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdTwo];
        NSDate *newDate =  [NSDate dateWithTimeIntervalSince1970:kCMHTestDateTwo];
        
        [stamperTwo saveLastSyncTime:newDate];
        
        expect(stamperOne.lastSyncStamp).to.equal(kCMHTestStampOne);
        expect(stamperTwo.lastSyncStamp).to.equal(kCMHTestStampTwo);
    });
    
    it(@"should forget sync times for one  user while updating those for another, w/o impacting each other", ^{
        CMHSyncStamper *stamperOne = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdOne];
        CMHSyncStamper *stamperTwo = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdTwo];
        NSDate *newDate =  [NSDate dateWithTimeIntervalSince1970:kCMHTestDateOne];
        
        [stamperOne forgetSyncTime];
        [stamperTwo saveLastSyncTime:newDate];
        
        expect(stamperOne.lastSyncStamp).to.equal(kCMHEpochStamp);
        expect(stamperTwo.lastSyncStamp).to.equal(kCMHTestStampOne);
    });
    
    afterAll(^{
        CMHSyncStamper *stamperOne = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdOne];
        [stamperOne forgetSyncTime];
        
        CMHSyncStamper *stamperTwo = [[CMHSyncStamper alloc] initWithCMHIdentifier:kCMHFakeIdTwo];
        [stamperTwo forgetSyncTime];
    });
});

SpecEnd
