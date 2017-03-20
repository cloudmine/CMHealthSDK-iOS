#import "CMHNewACLViewController.h"
#import "CMHTest-Secrets.h"

@interface CMHNewACLViewController ()<UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UITextField *genACLTextField;
@end

@implementation CMHNewACLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [CMAPICredentials sharedInstance].appIdentifier = CMHTestsAppId;
    [CMAPICredentials sharedInstance].appSecret = CMHTestsAPIKey;
    self.genACLTextField.delegate = self;
}

- (IBAction)didPressCreateButton:(UIButton *)sender
{
    CMUser *newUser = [[CMUser alloc] initWithEmail:self.emailTextField.text andPassword:self.passwordTextField.text];
    [newUser createAccountWithCallback:^(CMUserAccountResult createCode, NSArray *createMessages) {
        if (CMUserAccountOperationFailed(createCode)) {
            NSLog(@"[CMHealth] Failed to create new admin user, with code %li, messages: %@", (long)createCode, createMessages);
            return;
        }
        
        [newUser loginWithCallback:^(CMUserAccountResult loginCode, NSArray *loginMessages) {
            if (CMUserAccountOperationFailed(createCode)) {
                NSLog(@"[CMHealth] Failed to log new admin user in, with code %li, messages: %@", (long)loginCode, loginMessages);
                return;
            }
            
            [CMStore defaultStore].user = newUser;
        
            CMACL *newACL = [CMACL new];
            newACL.permissions = [NSSet setWithObjects:CMACLReadPermission, CMACLUpdatePermission, CMACLDeletePermission, nil];
            newACL.members = [NSSet setWithObjects:newUser.objectId, nil];
            
            [newACL save:^(CMObjectUploadResponse *response) {
                if (nil != response.error) {
                    NSLog(@"[CMHealth] Failed to create new Admin ACL: %@", response.error.localizedDescription);
                    return;
                }
                
                NSLog(@"[CMHealth] New ACL saved with status: %@", response.uploadStatuses[newACL.objectId]);
                NSLog(@"[CMHeatlh] New ACL ID: %@", newACL.objectId);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.genACLTextField.text = newACL.objectId;
                });
            }];
        }];
    }];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return NO;
}

@end
