#import "CMHNewAdminViewController.h"
#import "CMHTest-Secrets.h"

typedef void(^NADoneBlock)(void);
typedef void(^NAWaitBlock)(_Nonnull NADoneBlock done);

void na_wait_until(_Nonnull NAWaitBlock block)
{
    dispatch_group_t doneGroup = dispatch_group_create();
    
    NADoneBlock done = ^{
        dispatch_group_leave(doneGroup);
    };
    
    dispatch_group_enter(doneGroup);
    block(done);
    
    dispatch_group_wait(doneGroup, DISPATCH_TIME_FOREVER);
}


@interface CMHNewAdminViewController ()
@property (strong, nonatomic) IBOutlet UITextField *existingACLTextField;
@property (strong, nonatomic) IBOutlet UITextField *aclOwnerEmailTextField;
@property (strong, nonatomic) IBOutlet UITextField *aclOwnerPasswordTextField;
@property (strong, nonatomic) IBOutlet UITextField *createAdminEmailTextField;
@property (strong, nonatomic) IBOutlet UITextField *createAdminPasswordTextField;
@end

@implementation CMHNewAdminViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [CMAPICredentials sharedInstance].appIdentifier = CMHTestsAppId;
    [CMAPICredentials sharedInstance].appSecret = CMHTestsAPIKey;
}

- (IBAction)didPressCreateButton:(UIButton *)sender
{
    dispatch_queue_t runQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(runQueue, ^{
        [self logoutCurrentUser];
        
        __block NSError *signupError = nil;
        
        na_wait_until(^(NADoneBlock  _Nonnull done) {
            [[CMHUser currentUser] signUpWithEmail:self.createAdminEmailTextField.text password:self.createAdminPasswordTextField.text andCompletion:^(NSError * _Nullable error) {
                signupError = error;
                done();
            }];
        });
        
        if (nil != signupError) {
            NSLog(@"[CMHealth] Failed to create new Admin Account %@", signupError.localizedDescription);
            return;
        }
        
        NSLog(@"[CMHealth] Created new admin user with id: %@", [CMHUser currentUser].userData.userId);
        NSString *newUserId = [CMHUser currentUser].userData.userId;
        
        [self logoutCurrentUser];
        
        __block NSError *ownerLoginError = nil;
        
        
        na_wait_until(^(NADoneBlock  _Nonnull done) {
            [[CMHUser currentUser] loginWithEmail:self.aclOwnerEmailTextField.text password:self.aclOwnerPasswordTextField.text andCompletion:^(NSError *error) {
                ownerLoginError = error;
                done();
            }];
        });
        
        if (nil != ownerLoginError) {
            NSLog(@"[CMHealth] Failed Logging into existing admin user account, %@", ownerLoginError.localizedDescription);
            return;
        }
        
        NSLog(@"[CMHealth] Logged into existing admin user account");
        
        [CMStore defaultStore].user = [CMUser currentUser];
        
        __block CMACL *existingACL = nil;
        
        na_wait_until(^(NADoneBlock  _Nonnull done) {
            [[CMStore defaultStore] allACLs:^(CMACLFetchResponse *response) {
                if (nil != response.error) {
                    NSLog(@"[CMHealth] Failed to fetch ACLs, %@", response.error.localizedDescription);
                    done();
                    return;
                }
                
                for (CMACL *acl in response.acls) {
                    if (![acl isKindOfClass:[CMACL class]]) {
                        continue;
                    }
                    
                    if ([acl.objectId isEqualToString:self.existingACLTextField.text]) {
                        existingACL = acl;
                        break;
                    }
                }
                
                done();
            }];
        });
        
        if (nil == existingACL) {
            NSLog(@"[CMHEALTH] Failed to find existing ACL with specified ID");
            return;
        }
        
        NSMutableSet *memberSet = [existingACL.members mutableCopy];
        [memberSet addObject:newUserId];
        existingACL.members = [memberSet copy];
        
        [existingACL save:^(CMObjectUploadResponse *response) {
            if (nil != response.error) {
                NSLog(@"Failed to update existing ACL, error: %@", response.error.localizedDescription);
                return;
            }
            
            NSLog(@"[CMHealth] Successfully added new Admin user to the existing admin ACL with status %@", response.uploadStatuses[existingACL.objectId]);
        }];
        
    });
}

- (void)logoutCurrentUser
{
    if ([CMHUser currentUser].isLoggedIn) {
        
        __block NSError *logoutError = nil;
        na_wait_until(^(NADoneBlock  _Nonnull done) {
            [[CMHUser currentUser] logoutWithCompletion:^(NSError * _Nullable error) {
                logoutError = error;
                done();
            }];
        });
        
        if (nil != logoutError) {
            NSLog(@"[CMHealth] Failed to log user out, %@", logoutError.localizedDescription);
            return;
        }
        
        NSLog(@"[CMHealth] Logged out of current user account");
    }
}

@end
