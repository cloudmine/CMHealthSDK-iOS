#import <Foundation/Foundation.h>

@class CMObject;

typedef void(^CMHCareSaveCompletion)(NSString *_Nullable status, NSError *_Nullable error);

@interface CMHCareObjectSaver : NSObject

+ (void)saveCMHCareObject:(nonnull CMObject *)careObject withCompletion:(nonnull CMHCareSaveCompletion)block;

@end
