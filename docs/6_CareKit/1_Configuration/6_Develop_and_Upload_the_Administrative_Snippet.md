# Develop and Upload the Administrative Snippet

When an `OCKCarePlanEvent` or `OCKCarePlanActivity` object is saved, the Snippet is responsible for adding the admin `ACL` id value to the `[__access__]` field of the object, allowing for it to be shared with any CareKit admin user. An example snippet is provided here: [docs/AdministrativeSnippet/Example.js](docs/AdministrativeSnippet/Example.js).

Once completed, ensure that the Snippet is uploaded to CloudMine via the Compass dashboard. Take note of the name used to create it, as it wil be required when configuring your CloudMine app secrets in the next step.  
