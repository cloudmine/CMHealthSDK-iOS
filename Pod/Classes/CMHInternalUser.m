#import "CMHInternalUser.h"
#import "CMHInternalProfile.h"
#import "CMHErrorUtilities.h"

@interface CMHInternalUser ()
@property (nonatomic, nullable) CMHInternalProfile *profile;
@end

@implementation CMHInternalUser

+ (instancetype)currentUser
{
    return [super currentUser];
}

- (instancetype)initWithEmail:(NSString *)theEmail andPassword:(NSString *)thePassword
{
    self = [super initWithEmail:theEmail andPassword:thePassword];
    if (nil == self) return nil;

    self.profile = [CMHInternalProfile new];
    self.profileId = self.profile.objectId;

    return self;
}

#pragma mark Public

- (void)signUpWithEmail:(NSString *)email password:(NSString *)password andCompletion:(CMHUserAuthCompletion)block
{
    [self createAccountWithCallback:^(CMUserAccountResult createResultCode, NSArray *messages) {
        NSError *createError = [CMHErrorUtilities errorForAccountResult:createResultCode];
        if (nil != createError) {
            if (nil != block) {
                block(createError);
            }
            return;
        }

        [self loginWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
            NSError *loginError = [CMHErrorUtilities errorForAccountResult:resultCode];
            if (nil != loginError) {
                if (nil != block) {
                    block(loginError);
                }
                return;
            }

            [CMStore.defaultStore saveUserObject:self.profile callback:^(CMObjectUploadResponse *response) {
                NSError *saveError = [CMHErrorUtilities errorForKind:@"user profile" objectId:self.profile.objectId uploadResponse:response];
                if (nil != saveError) {
                    if (nil != block) {
                        block(saveError);
                    }
                    return;
                }

                if (nil != block) {
                    block(nil);
                }
            }];
        }];
    }];
}

- (BOOL)hasName
{
    return !(nil == self.familyName || [@"" isEqualToString:self.familyName] || nil == self.givenName || [@"" isEqualToString:self.givenName]);
}

# pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (nil == self) return nil;

    self.givenName = [aDecoder decodeObjectForKey:@"givenName"];
    self.familyName = [aDecoder decodeObjectForKey:@"familyName"];
    self.profileId = [aDecoder decodeObjectForKey:@"profileId"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];

    if (nil != self.givenName) {
        [aCoder encodeObject:self.givenName forKey:@"givenName"];
    }

    if (nil != self.familyName) {
        [aCoder encodeObject:self.familyName forKey:@"familyName"];
    }

    if (nil != self.profileId) {
        [aCoder encodeObject:self.profileId forKey:@"profileId"];
    }
}

@end
