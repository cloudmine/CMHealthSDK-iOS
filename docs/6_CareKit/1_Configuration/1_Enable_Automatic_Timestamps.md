# Enable Automatic Timestamps 

The automatic timestamps (`auto_ts`) feature must be enabled for your `app_id`. This feature can be enabled by running the following `cURL` request. 

Once `auto_ts` is enabled, all application and user-level objects will be updated with `__updated__` and `__created__` key-value pairs, which will automatically be maintained by the CloudMine platform. 

*Note: `auto_ts` is a cached configuration value, and it may take up to 15 minutes for the setting to take full effect.*

#### Request
```http
curl -X POST \
  https://api.cloudmine.io/admin/app/:app_id/prefs \
  -H 'content-type: application/json' \
  -H 'x-cloudmine-apikey: :master_api_key' \
  -d '{
	"auto_ts":true
}'
```
1. `app_id`: Required. App identifier from the Compass dashboard.
2. `master_api_key`: Required. Available within the Compass Dashboard. 

#### Response

```http
HTTP/1.1 200 OK
```
If a `4xx` error code is observed, please ensure that the `Master API Key` is being used to execute the request. 