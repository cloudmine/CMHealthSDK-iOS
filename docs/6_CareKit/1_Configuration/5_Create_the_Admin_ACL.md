# Create the Admin ACL

The admin `ACL` will be used to ensure that patient data can be recalled via the administrative user. The `[members]` array is used for tracking all admin user `__id__` values, which may be added at will. Patient data will automatically be available to them once logged in. 

#### Request
```http
curl -X POST \
  'https://api.cloudmine.io/v1/app/:app_id/user/access?userid=:admin_user_id' \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :master_api_key' \
  -d '{
    "members": [":admin_user_id"],
    "permissions": ["r", "c", "u", "d"],
    "my_extra_info": "for CK admins"
}'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `master_api_key`: Required. Available within the Compass Dashboard.
3. `admin_user_id`: Required. Refers to the administrative user's `__id__`. 

#### Response
```http
HTTP/1.1 201 OK
{
  "454a72bf7ae54f73abd33d0d3690d822": {
    "__type__": "acl",
    "__id__": "454a72bf7ae54f73abd33d0d3690d822",
    "permissions": [
      "r",
      "c",
      "u",
      "d"
    ],
    "members": [
      "44629a07c9014d2eba92ae9dca1d813a"
    ],
    "segments": {}
  }
}
```

Please take note of the `__id__` value returned for the newly created `ACL`. It will be required in the next step. 
