# Creating the `CMHCarePlanStore`

Simply replace the `OCKCarePlanStore` with an 
instance of our custom subclass, `CMHCarePlanStore`, and your user's data will be 
automatically pushed to CloudMine.

```Objective-C
#import <CMHealth/CMHealth.>

// `self.carePlanStore` is assumed to be a @property of type CMHCarePlanStore
self.carePlanStore = [CMHCarePlanStore storeWithPersistenceDirectoryURL:BCMStoreUtils.persistenceDirectory];
self.carePlanStore.delegate = self;
```

As long as your patient user is logged in and your CloudMine account is properly configured,
your CareKit app will now automatically push changes made in the local store up to
the cloud.
