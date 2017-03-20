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
        
        CMUser *newUser = [[CMUser alloc] initWithEmail:self.createAdminEmailTextField.text andPassword:self.createAdminPasswordTextField.text];
        
        __block CMUserAccountResult createCode = CMUserAccountUnknownResult;
        __block NSArray *createMessages = nil;
        
        na_wait_until(^(NADoneBlock  _Nonnull done) {
            [newUser createAccountWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
                createCode = resultCode;
                createMessages = messages;
                done();
            }];
        });
        
        if (CMUserAccountOperationFailed(createCode)) {
            NSLog(@"[CMHealth] Failed to create new Admin Account. Code: %li, messages: %@", (long)createCode, createMessages);
            return;
        }
        
        NSLog(@"[CMHealth] Created new admin user with id: %@", newUser.objectId);
        
        [self logoutCurrentUser];
        
        CMUser *aclOwner = [[CMUser alloc] initWithEmail:self.aclOwnerEmailTextField.text andPassword:self.aclOwnerPasswordTextField.text];
        
        __block CMUserAccountResult loginCode = CMUserAccountUnknownResult;
        
        na_wait_until(^(NADoneBlock  _Nonnull done) {
            [aclOwner loginWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
                loginCode = resultCode;
                done();
            }];
        });
        
        if (CMUserAccountOperationFailed(loginCode)) {
            NSLog(@"[CMHealth] Failed Logging into existing admin user account, code: %li", (long)loginCode);
            return;
        }
        
        NSLog(@"[CMHealth] Logged into existing admin user account");
        
        [CMStore defaultStore].user = aclOwner;
        
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
        [memberSet addObject:newUser.objectId];
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
    if ([CMUser currentUser].isLoggedIn) {
        __block CMUserAccountResult logoutCode = CMUserAccountUnknownResult;
        
        na_wait_until(^(NADoneBlock  _Nonnull done) {
            [[CMUser currentUser] logoutWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
                logoutCode = resultCode;
                done();
            }];
        });
        
        if (CMUserAccountOperationFailed(logoutCode)) {
            NSLog(@"[CMHealth] Failed to log user out, code: %li", (long)logoutCode);
            return;
        }
        
        NSLog(@"[CMHealth] Logged out of current user account");
    }
}

@end
