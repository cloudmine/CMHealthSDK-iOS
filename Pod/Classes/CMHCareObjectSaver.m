#import "CMHCareObjectSaver.h"
#import <CloudMine/CloudMine.h>
#import "CMHErrorUtilities.h"

static NSString *_Nonnull const CMHSaveCareObjectSnippetName = @"insertCareKitObject";
static NSString *_Nonnull const CMHSaveSessionTokenParamKey  = @"session_token";
static NSString *_Nonnull const CMHSaveCareObjectParamKey    = @"care_object";
static NSString *_Nonnull const CMHSaveResultBodyKey         = @"result";
static NSString *_Nonnull const CMHSaveResultErrorKey        = @"error";
static NSString *_Nonnull const CMHSaveResultSuccessKey      = @"success";

@implementation CMHCareObjectSaver

+ (void)saveCMHCareObject:(nonnull CMObject *)careObject withCompletion:(nonnull CMHCareSaveCompletion)block
{
    NSAssert(nil != careObject, @"Cannot call %@ without a care object parameter", __PRETTY_FUNCTION__);
    NSAssert(nil != block, @"Cannot call %@ without a completion block", __PRETTY_FUNCTION__);
    NSAssert([CMUser currentUser].isLoggedIn, @"Cannot invoke %@ without a logged in user", __PRETTY_FUNCTION__);
    
    NSDictionary *encodingResult = [CMObjectEncoder encodeObjects:@[careObject]];
    NSDictionary *encodedCareObject = encodingResult[careObject.objectId];
    
    NSAssert(nil != encodedCareObject, @"Failed to encode care object: %@", careObject);
    NSAssert(nil != encodedCareObject[@"cmh_owner"], @"CareObject Parameter: %@ does not conform to contract of snippet: %@, requires a cmh_owner parameter", careObject, CMHSaveCareObjectSnippetName);
    
    CMWebService *webService = [CMStore defaultStore].webService;
    NSDictionary *parameters = @{ CMHSaveSessionTokenParamKey: [CMUser currentUser].token,
                                  CMHSaveCareObjectParamKey: encodedCareObject };
    
    NSError *jsonError = nil;
    NSData *parameterData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&jsonError];
    
    if (nil != jsonError) {
        block(nil, jsonError);
        return;
    }
    
    [webService runPOSTSnippet:CMHSaveCareObjectSnippetName withBody:parameterData user:[CMUser currentUser] successHandler:^(id snippetResponse, NSDictionary *headers) {
        if (nil == snippetResponse || ![snippetResponse isKindOfClass:[NSDictionary class]]) {
            NSString *errorMessage = [NSString localizedStringWithFormat:@"Invalid Response from %@ snippet: %@", CMHSaveCareObjectSnippetName, snippetResponse];
            NSError *error = [CMHErrorUtilities errorWithCode:CMHErrorCareObjectSaveError localizedDescription:errorMessage];
            block(nil, error);
            return;
        }
        
        NSDictionary *result = (NSDictionary *)snippetResponse;
        
        NSString *resultErrorMessage = result[CMHSaveResultErrorKey];
        if (nil != resultErrorMessage) {
            resultErrorMessage = [NSString stringWithFormat:@"%@", resultErrorMessage]; // just in case it's not a string!
            NSError *error = [CMHErrorUtilities errorWithCode:CMHErrorCareObjectSaveError localizedDescription:resultErrorMessage];
            block(nil, error);
            return;
        }
        
        NSDictionary *successDictionary = result[CMHSaveResultSuccessKey];
        if (nil == successDictionary || ![successDictionary isKindOfClass:[NSDictionary class]] || nil == successDictionary[careObject.objectId]) {
            NSString *errorMessage = [NSString localizedStringWithFormat:@"Ambiguous response from %@ snippet: %@", CMHSaveCareObjectSnippetName, successDictionary];
            NSError *error = [CMHErrorUtilities errorWithCode:CMHErrorCareObjectSaveError localizedDescription:errorMessage];
            block(nil, error);
            return;
        }
        
        block(successDictionary[careObject.objectId], nil);
    } errorHandler:^(NSError *error) {
        block(nil, error);
    }];
}

@end
