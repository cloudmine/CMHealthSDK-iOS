# Reference the Admin Profile 

Once the private profile has been created, the CareKit framework will expect to find a reference to it on the public profile. We need to update the public profile so as to ensure the profile data loads properly when the user logs in:

#### Request
```http
curl -X POST \
  'https://api.cloudmine.io/v1/app/:app_id/account/?userid=:admin_user_id' \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :master_api_key' \
  -d '{ 
  "profileId":"generate-unique-profile-key"
}'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `admin_user_id`: Required. Refers to the administrative user's `__id__`. 
3. `master_api_key`: Required. Available within the Compass Dashboard. 
4. `generate-unique-profile-key`: Required. Refers to the object key used to create the private admin profile.

#### Response
```http
HTTP/1.1 200 OK
```
Congrats! The first admin user has been successfully prepared. 
