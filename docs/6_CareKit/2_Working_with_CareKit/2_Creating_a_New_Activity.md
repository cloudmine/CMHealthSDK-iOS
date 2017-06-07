# Creating a New Activity 

For example, adding a new activity to the store will result in a representation of that activity
being pushed to CloudMine's backend for the current user.

```Objective-C
#import <CMHealth/CMHealth.h>

// Create a standard OCKCarePlanActivity instance somewhere in your app
OCKCarePlanActivity *activity = [self activityGenerator];

// Add this activity to the store as you would in a standard CareKit app
[self.carePlanStore addActivity:activity completion:^(BOOL success, NSError * _Nullable error) {
    if (!success) {
		NSLog(@"Failed to add activity to store: %@", error.localizedDescription);
		return;
    }
    
    NSLog(@"Activity added to store");
}];
```

Note the above code is no different from what you would write for a standard, local-only, CareKit app.
No additional consideration is required to push `CMHCarePlanStore` entries to CloudMine!