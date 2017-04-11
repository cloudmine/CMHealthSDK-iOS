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
    [[CMHUser currentUser] signUpWithEmail:self.emailTextField.text password:self.passwordTextField.text andCompletion:^(NSError * _Nullable error) {
        if (nil != error) {
            NSLog(@"[CMHealth] Failed to create new admin user, %@", error.localizedDescription);
            return;
        }
        
        
        CMHMutableUserData *userData = [[CMHUser currentUser].userData mutableCopy];
        userData.isAdmin = YES; // TODO: Update encode with coder so this is actually saved
        
        [[CMHUser currentUser] updateUserData:[userData copy] withCompletion:^(CMHUserData * _Nullable userData, NSError * _Nullable error) {
            if (nil != error) {
                NSLog(@"[CMHealth] Failed to tag new user as admin %@", error.localizedDescription);
                return;
            }
            
            CMACL *newACL = [CMACL new];
            newACL.permissions = [NSSet setWithObjects:CMACLReadPermission, CMACLUpdatePermission, CMACLDeletePermission, nil];
            newACL.members = [NSSet setWithObjects:userData.userId, nil];
            
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
