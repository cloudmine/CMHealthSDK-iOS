#import "CMHCarePlanStoreVendor.h"
#import "CMHCarePlanStore_internal.h"

@interface CMHCarePlanStoreVendor ()

@property (nonatomic, nonnull) NSMutableDictionary<NSString *, CMHCarePlanStore *> *existingStores;

@end

@implementation CMHCarePlanStoreVendor

- (instancetype)init
{
    self = [super init];
    if (nil == self) { return nil; }
    
    _existingStores = [NSMutableDictionary new];
    
    return self;
}

+ (instancetype)sharedVendor
{
    static dispatch_once_t onceToken;
    static CMHCarePlanStoreVendor *sharedInstance = nil;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CMHCarePlanStoreVendor alloc] init];
    });
    
    return sharedInstance;
}

- (CMHCarePlanStore *)storeForCMHIdentifier:(NSString *)identifier atDirectory:(NSURL *)URL
{
    CMHCarePlanStore *existingStore = [self.existingStores objectForKey:identifier];
    
    if (nil != existingStore) {
        NSAssert([existingStore.directoryURL isEqual:URL],
                 @"Disallowed: requested a store for identifier (%@) at a different directory (%@) than previously requested (%@)",
                 identifier, URL, existingStore.directoryURL);
        
        return existingStore;
    }
    
    CMHCarePlanStore *newStore = [[CMHCarePlanStore alloc] initWithPersistenceDirectoryURL:URL andCMHIdentifier:identifier];
    self.existingStores[identifier] = newStore;
    
    return newStore;
}

- (void)forgetStoreWithCMHIdentifier:(NSString *)cmhIdentifier
{
    [self.existingStores removeObjectForKey:cmhIdentifier];
}

- (void)forgetStores
{
    self.existingStores = [NSMutableDictionary new];
}

@end
