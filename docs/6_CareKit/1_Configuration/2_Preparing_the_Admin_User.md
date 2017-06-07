# Preparing the Admin User

An initial administrative user is required in order to retrieve patient-level data using CloudMine's `ACL` framework. To create the administrative user, the below `cURL` may be used: 

#### Request
```http
curl -X POST \
  https://api.cloudmine.io/v1/app/:app_id/account/create \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :api_key' \
  -d '
{
    "credentials": {
        "email": "admin@example.com",
        "password": "the-password"
    },
    "profile": {
        "name": "Admin User",
        "email":"admin@example.com"
    }
}'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `api_key`: Required. Available within the Compass Dashboard.
3. `credentials.email`: Required. Refers to the administrative user's email address. 
4. `credentials.password`: Required. Sets the initial administrative password. 
5. `profile.email`: Required. Refers to the administrative user's email address. 

#### Response
```http
HTTP/1.1 201 OK
{
	"name": "Admin User",
	"email": "admin@example.com",
	"__type__": "user",
	"__id__": "54e952dd255e42ada66f04bd1d938325"
}
```

Please take note of the user `__id__` value returned -- it will be required in a future step in order to create the admin `ACL`. 