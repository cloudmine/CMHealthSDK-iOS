# Create the Admin Profile

In some cases, the admin profile may contain sensitive information. To account for this, the admin profile should be created as a user-level object and referenced by `__id__` on the public profile. 

#### Request
```http
curl -X POST \
  'https://api.cloudmine.io/v1/app/:app_id/user/text?userid=:admin_user_id' \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :master_api_key' \
  -d '{
    "generate-unique-profile-key": {
      "__id__": "unique-object-key",
      "cmh_owner": ":admin_user_id",
      "__access__": [
        null
      ],
      "gender": null,
      "isAdmin": true,
      "dateOfBirth": null,
      "__class__": "CMHInternalProfile",
      "email": ":admin_email",
      "familyName": null,
      "givenName": null,
      "userInfo": {
        "__class__": "map"
      },
      "__created__": "2017-06-01T15:33:46Z",
      "__updated__": "2017-06-01T15:57:43Z"
    }
  }'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `admin_user_id`: Required. Refers to the administrative user's `__id__`. 
3. `master_api_key`: Required. Available within the Compass Dashboard. 

#### Response
```http
HTTP/1.1 200 OK
{
  "success": {
    "036f5dfc5a7fdb4819c80d86429ed126": "created"
  },
  "errors": {}
}
```
Please note the value used for `generate-unique-profile-key` as it will be required in the next step. 