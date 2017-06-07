# Synchronizing from the Server

Fetching updates _from_ the cloud is similiarly simple. A single method allows you to synchronize the local store 
with all data that has been added remotely since the last time it was called successfully.

```Objective-C
#import <CMHealth/CMHealth.h>

[self.carePlanStore syncFromRemoteWithCompletion:^(BOOL success, NSArray<NSError *> * _Nonnull errors) {
    if (!success) {
        NSLog(@"Error(s) syncing remote data %@", errors);
        return;
    }
        
    NSLog(@"Successful sync of remote data");
 }];
```

This allows your app to sync across devices and sessions with minimal effort.
