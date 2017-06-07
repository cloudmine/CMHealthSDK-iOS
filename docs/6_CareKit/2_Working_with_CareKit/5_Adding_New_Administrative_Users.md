# Adding New Administrative Users

Adding new Administrative Users requires 3 steps:

1. create the admin user
2. toggle the `isAdmin` field to `true` within the object's `CMHUserData` property,
3. add the admin `user_id` to the `[members]` field on the `acl_id` as described in the [Create the Admin `ACL`](#create-the-admin-acl) section. 

#### Creating the Admin User

The `CMUser` class contains the below method in order to create a new user within your CareKit implementation:

```Objective-C
- (void)signUpWithEmail:(NSString *_Nonnull)email
               password:(NSString *_Nonnull)password
          andCompletion:(_Nullable CMHUserAuthCompletion)block;
```
Once the user is successfully created, you are ready to move onto the next step. 

#### Creating the Admin CMHUserData Object 

The `CMHUserData` class represents additional profile data about the administrative user. In addition to representing basic details about the user, it also contains a `BOOL` property (`isAdmin`) in order to denote if the user is  indeed an admin. Once you have created an instance of `CMHUserData`, it can be attached to the target `CMHUser` using the below `CMHUser` method call:

```Objective-C
- (void)updateUserData:(CMHUserData *_Nonnull)userData
        withCompletion:(_Nullable CMHUpdateUserDataCompletion)block;
```
*Note: please ensure that the `isAdmin` boolean is set to true before calling this method, otherwise the underlying framework may not properly recognize this user as an administrator.*

#### Adding the Admin `user_id` to the Administrative ACL

After creating the user and their correpsonding profile data, the user's `__id__` value needs to be added to the admin `acl`. The below cURL request may be used as an example of how to perform this action:

##### Request
```http
curl -X POST \
  'https://api.cloudmine.io/v1/app/:app_id/user/access/:admin_acl_id?userid=:admin_user_id' \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :master_api_key' \
  -d '{
    "members": [":new_admin_id",":existing_admin_ids"]
}'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `admin_acl_id`: Required. Generated when first implementing CareKit within your App. 
3. `admin_user_id`: Required. Refers to the administrative user's `__id__`. 
4. `master_api_key`: Required. Available within the Compass Dashboard.
5. `new_admin_id`: Required. The `user_id` of the new admin to be enabled. 
6. `existing_admin_ids`: Required. Refers to existing admin users so as to ensure they are not overwritten during the insert for a net-new admin. 

##### Response
```http
HTTP/1.1 200 OK
```

*Note: it is strongly recommended that this workflow is implemented as a server-side Snippet within your larger application. Either the Master API Key or the root Admin user's password will be required in order to update the CareKit ACL. If the Master API Key is used client-side, ensure that it is handled securely or cycle the Master API Key upon completion and update the Administrative Snippet to reflect the new key.*
