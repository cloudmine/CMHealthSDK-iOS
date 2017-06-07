# Fetching All Patients

To help organizations access the patient-generated CareKit data, the `CMHealth` SDK allows for fetching an aggregated view of all patients and their activity/event data based on the `ACL` we created in the configuration section. This method requires that an admin CareKit user is signed-in. 

To fetch a list of `OCKPatient` instances for use within your application, call the
`fetchAllPatientsWithCompletion:` class method on `CMHCarePlanStore`:

```Objective-C
[CMHCarePlanStore fetchAllPatientsWithCompletion:^(BOOL success, NSArray<OCKPatient *> * _Nonnull patients, NSArray<NSError *> * _Nonnull errors) {
	if (!success) {
        NSLog(@"Errorse fetching patients: %@", errors);
        return;
	}
        
    self.patients = patients;
}];

```

Subsequent calls to this class method will return a list of updated patients, but will
intelligently sync _only_ data added or updated since the
last time it was called.
